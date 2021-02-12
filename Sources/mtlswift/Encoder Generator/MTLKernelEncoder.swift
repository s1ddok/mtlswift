public struct MTLKernelEncoder {

    public struct Parameter {
        public enum Kind {
            case texture, inPlaceTexture, buffer, sampler, threadgroupMemory
        }
        public var name: String
        public var swiftTypeName: String

        public var kind: Kind
        public var index: Int

        public var defaultValueString: String? = nil
    }

    public enum ThreadgroupMemoryLengthCalculation {
        case total(index: Int, bytes: Int)
        case perThread(index: Int, bytes: Int)
        case parameterPerThread(index: Int, parameterName: String)
    }

    public struct EncodingVariant {
        public var dispatchType: DispatchType
        public var threadgroupSize: ThreadgroupSize
    }

    public var shaderName: String
    public var swiftName: String
    public var accessLevel: AccessLevel
    public var parameters: [Parameter]
    public var encodingVariants: [EncodingVariant]
    public var usedConstants: [ASTFunctionConstant]
    public var branchingConstant: ASTFunctionConstant?
    public var threadgroupMemoryCalculations: [ThreadgroupMemoryLengthCalculation]

    public var shaderString: String {
        let sourceBuilder = SourceStringBuilder()
        sourceBuilder.begin()

        sourceBuilder.add(line: "\(self.accessLevel.rawValue) class \(self.swiftName) {")
        sourceBuilder.blankLine()
        sourceBuilder.pushLevel()

        if let bc = self.branchingConstant {
            sourceBuilder.add(line: "\(self.accessLevel.rawValue) let \(bc.name): \(bc.type.swiftTypeDelcaration)")
        }

        let inPlaceTextures = self.parameters.filter { $0.kind == .inPlaceTexture }
        let containsInPlaceTextures = !inPlaceTextures.isEmpty

        sourceBuilder.blankLine()
        sourceBuilder.add(line: "\(self.accessLevel.rawValue) let pipelineState: MTLComputePipelineState")
        if containsInPlaceTextures {
            sourceBuilder.add(line: "\(self.accessLevel.rawValue) let textureCopy: TextureCopy")
        }
        sourceBuilder.blankLine()

        if self.usedConstants.isEmpty && self.branchingConstant == nil {
            // MARK: Generate inits
            if containsInPlaceTextures {
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) init(library: MTLLibrary, textureCopy: TextureCopy) throws {")
            } else {
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) init(library: MTLLibrary) throws {")
            }
            sourceBuilder.pushLevel()

            sourceBuilder.add(line: "self.pipelineState = try library.computePipelineState(function: \"\(self.shaderName)\")")
        } else {
            let parameterString = ", " + self.usedConstants.map { "\($0.name): \($0.type.swiftTypeDelcaration)" }.joined(separator: ", ")

            if containsInPlaceTextures {
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) init(library: MTLLibrary, textureCopy: TextureCopy\(self.usedConstants.isEmpty ? "" : parameterString)) throws {")
            } else {
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) init(library: MTLLibrary\(self.usedConstants.isEmpty ? "" : parameterString)) throws {")
            }

            sourceBuilder.pushLevel()

            sourceBuilder.add(line: "let constantValues = MTLFunctionConstantValues()")
            if let bc = self.branchingConstant {
                sourceBuilder.add(line: "self.\(bc.name) = library.device.supports(feature: .nonUniformThreadgroups)")
                sourceBuilder.add(line: "constantValues.set(self.\(bc.name), at: \(bc.index))")
            }

            for constant in self.usedConstants {
                switch constant.type {
                case .ushort2: sourceBuilder.add(line: "constantValues.set(\(constant.name), type: .ushort2, at: \(constant.index))")
                default: sourceBuilder.add(line: "constantValues.set(\(constant.name), at: \(constant.index))")
                }
            }

            sourceBuilder.add(line: "self.pipelineState = try library.computePipelineState(function: \"\(self.shaderName)\", constants: constantValues)")
        }

        if containsInPlaceTextures {
            sourceBuilder.add(line: "self.textureCopy = textureCopy")
        }

        // MARK: Balancing for init
        sourceBuilder.popLevel()
        sourceBuilder.add(line: "}")

        sourceBuilder.blankLine()

        // MARK: Generate encoding
        for (idx, ev) in self.encodingVariants.enumerated() {
            var threadgroupParameterString = ""
            var threadgroupVariableString = ""
            let threadgroupExpressionString = ", threadgroupSize: _threadgroupSize"

            switch ev.threadgroupSize {
            case .provided:
                threadgroupParameterString = "threadgroupSize: MTLSize, "
                threadgroupVariableString = "let _threadgroupSize = threadgroupSize"
            case .max:
                threadgroupVariableString = "let _threadgroupSize = self.pipelineState.max2dThreadgroupSize"
            case .executionWidth:
                threadgroupVariableString = "let _threadgroupSize = self.pipelineState.executionWidthThreadgroupSize"
            case .constant(_, _, _):
                threadgroupVariableString = "let _threadgroupSize = \(self.swiftName).threadgroupSize\(idx)"
            }

            var gridSizeParameterString = ""
            switch ev.dispatchType {
            case .exact(parameters: .provided),
                 .even(parameters: .provided),
                 .optimal(_, parameters: .provided):
                gridSizeParameterString = "gridSize: MTLSize, "
            default: ()
            }

            if self.parameters.isEmpty {
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) func encode(\(gridSizeParameterString)\(threadgroupParameterString)using encoder: MTLComputeCommandEncoder) {")
            } else {
                var parameterString = ""
                for parameter in self.parameters {
                    parameterString += "\(parameter.name): \(parameter.swiftTypeName), "
                }

                var parametersBodyString = ""
                let gridSizeValueString = gridSizeParameterString.isEmpty ? "" : ", gridSize: gridSize"
                let threadgroupSizeValueString = threadgroupParameterString.isEmpty ? "" : ", threadgroupSize: threadgroupSize"
                for parameterIndex in 0 ..< self.parameters.count {
                    let parameterName = self.parameters[parameterIndex].name
                    let parameterSeparator = parameterIndex < self.parameters.count - 1 ? ", " : ""
                    parametersBodyString += parameterName + ": " + parameterName + parameterSeparator
                }

                // Call as function in commandBuffer
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) func callAsFunction(\(parameterString)\(gridSizeParameterString)\(threadgroupParameterString)in commandBuffer: MTLCommandBuffer) {")
                sourceBuilder.pushLevel()
                sourceBuilder.add(line: "self.encode(\(parametersBodyString)\(gridSizeValueString)\(threadgroupSizeValueString), in: commandBuffer)")
                sourceBuilder.popLevel()
                sourceBuilder.add(line: "}")

                // Call as function using encoder
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) func callAsFunction(\(parameterString)\(gridSizeParameterString)\(threadgroupParameterString)using encoder: MTLComputeCommandEncoder) {")
                sourceBuilder.pushLevel()
                sourceBuilder.add(line: "self.encode(\(parametersBodyString)\(gridSizeValueString)\(threadgroupSizeValueString), using: encoder)")
                sourceBuilder.popLevel()
                sourceBuilder.add(line: "}")

                // Encode in commandBuffer
                sourceBuilder.add(line: "\(self.accessLevel.rawValue) func encode(\(parameterString)\(gridSizeParameterString)\(threadgroupParameterString)in commandBuffer: MTLCommandBuffer) {")
                sourceBuilder.pushLevel()
                
                if containsInPlaceTextures {
                    for inPlaceTextureParameter in inPlaceTextures {
                        let name = inPlaceTextureParameter.name
                        let imageCopyName = "\(name)CopyImage"
                        let originalTextureName = "\(name)OriginalTexture"

                        sourceBuilder.add(line: "var \(name) = \(name)")
                        sourceBuilder.add(line: "if !self.pipelineState.device.supports(feature: .readWriteTextures(\(name).pixelFormat)) {")
                        sourceBuilder.pushLevel()

                        sourceBuilder.add(line: "let \(originalTextureName) = \(name)")
                        sourceBuilder.add(line: "let \(imageCopyName) = \(name).matchingTemporaryImage(commandBuffer: commandBuffer)")
                        sourceBuilder.add(line: "defer { \(imageCopyName).readCount = .zero }")
                        sourceBuilder.add(line: "\(name) = \(imageCopyName).texture")
                        sourceBuilder.add(line: "self.textureCopy(source: \(originalTextureName), destination: \(name), in: commandBuffer)")
                        sourceBuilder.add(line: "}")
                        sourceBuilder.popLevel()

                        sourceBuilder.blankLine()
                    }
                }

                sourceBuilder.add(line: "commandBuffer.compute { encoder in")
                sourceBuilder.pushLevel()
                sourceBuilder.add(line: "encoder.label = \"\(self.swiftName)\"")
                sourceBuilder.add(line: "self.encode(\(parametersBodyString)\(gridSizeValueString)\(threadgroupSizeValueString), using: encoder)")
                sourceBuilder.popLevel()
                sourceBuilder.add(line: "}")
                sourceBuilder.popLevel()
                sourceBuilder.add(line: "}")

                // Ecode using encoder
                let accessLevel = containsInPlaceTextures ? "private" : "\(self.accessLevel.rawValue)"
                sourceBuilder.add(line: "\(accessLevel) func encode(\(parameterString)\(gridSizeParameterString)\(threadgroupParameterString)using encoder: MTLComputeCommandEncoder) {")
            }
            sourceBuilder.pushLevel()
            sourceBuilder.add(line: threadgroupVariableString)

            for parameter in self.parameters {
                switch parameter.kind {
                case .buffer:
                    if parameter.swiftTypeName == "MTLBuffer" {
                        sourceBuilder.add(line: "encoder.setBuffer(\(parameter.name), offset: 0, index: \(parameter.index))")
                    } else {
                        sourceBuilder.add(line: "encoder.setValue(\(parameter.name), at: \(parameter.index))")
                    }
                case .texture, .inPlaceTexture:
                    sourceBuilder.add(line: "encoder.setTexture(\(parameter.name), index: \(parameter.index))")
                case .sampler:
                    sourceBuilder.add(line: "encoder.setSamplerState(\(parameter.name), index: \(parameter.index))")
                case .threadgroupMemory:
                    sourceBuilder.add(line: "encoder.setThreadgroupMemoryLength(\(parameter.name), index: \(parameter.index))")
                }
            }

            for calculation in self.threadgroupMemoryCalculations {
                switch calculation {
                case .total(let index, let bytes):
                    sourceBuilder.add(line: "encoder.setThreadgroupMemoryLength(\(bytes), index: \(index))")
                case .perThread(let index, let bytes):
                    sourceBuilder.add(line: "encoder.setThreadgroupMemoryLength(_threadgroupSize.width * _threadgroupSize.height * _threadgroupSize.depth * \(bytes), index: \(index))")
                case .parameterPerThread(let index, let parameter):
                    sourceBuilder.add(line: "encoder.setThreadgroupMemoryLength(_threadgroupSize.width * _threadgroupSize.height * _threadgroupSize.depth * \(parameter), index: \(index))")
                }
            }

            sourceBuilder.blankLine()

            switch ev.dispatchType {
            case .none:
                sourceBuilder.add(line: "encoder.setComputePipelineState(self.pipelineState)")

            // MARK: Even dispatching
            case .even(parameters: .provided):
                sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, covering: gridSize\(threadgroupExpressionString))")

            case .even(parameters: .constant(_, _, _)):
                sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, covering: \(self.swiftName).gridSize\(idx)\(threadgroupExpressionString))")

            case .even(parameters: .over(let argument)):
                if let targetParameter = self.parameters.first(where: { $0.name == argument }),
                   (targetParameter.kind == .texture || targetParameter.kind == .inPlaceTexture) {
                    sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, covering: \(targetParameter.name).size\(threadgroupExpressionString))")
                } else {
                    fatalError("Could not generate dispatching over parameter \(argument)")
                }

            // MARK: Exact dispatching
            case .exact(parameters: .provided):
                sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, exactly: gridSize\(threadgroupExpressionString))")

            case .exact(parameters: .constant(_, _, _)):
                sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, exactly: \(self.swiftName).gridSize\(idx)\(threadgroupExpressionString))")

            case .exact(parameters: .over(let argument)):
                if let targetParameter = self.parameters.first(where: { $0.name == argument }),
                   (targetParameter.kind == .texture || targetParameter.kind == .inPlaceTexture) {
                    sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, exactly: \(targetParameter.name).size\(threadgroupExpressionString))")
                } else {
                    print("Could not generate dispatching over parameter \(argument)")
                }

            // MARK: Optimal dispatching
            case .optimal(_, parameters: .provided):
                let bc = self.branchingConstant!
                sourceBuilder.add(line: "if self.\(bc.name) { encoder.dispatch2d(state: self.pipelineState, exactly: gridSize\(threadgroupExpressionString)) } else { encoder.dispatch2d(state: self.pipelineState, covering: gridSize\(threadgroupExpressionString)) }")
            case .optimal(_, parameters: .constant(_, _, _)):
                let bc = self.branchingConstant!
                sourceBuilder.add(line: "if self.\(bc.name) { encoder.dispatch2d(state: self.pipelineState, exactly: \(self.swiftName).gridSize\(idx)\(threadgroupExpressionString)) } else { encoder.dispatch2d(state: self.pipelineState, covering: \(self.swiftName).gridSize\(idx)\(threadgroupExpressionString)) }")
            case .optimal(_, parameters: .over(let argument)):
                if let targetParameter = self.parameters.first(where: { $0.name == argument }),
                   (targetParameter.kind == .texture || targetParameter.kind == .inPlaceTexture) {
                    let bc = self.branchingConstant!
                    sourceBuilder.add(line: "if self.\(bc.name) { encoder.dispatch2d(state: self.pipelineState, exactly: \(targetParameter.name).size\(threadgroupExpressionString)) } else { encoder.dispatch2d(state: self.pipelineState, covering: \(targetParameter.name).size\(threadgroupExpressionString)) }")
                } else { print("Could not generate dispatching over parameter \(argument)") }
            }

            sourceBuilder.popLevel()
            sourceBuilder.add(line: "}")
        }

        sourceBuilder.blankLine()
        // MARK: Declare static constants
        for (idx, ev) in self.encodingVariants.enumerated() {
            if case .constant(let x, let y, let z) = ev.threadgroupSize {
                sourceBuilder.add(line: "private static let threadgroupSize\(idx) = MTLSize(width: \(x), height: \(y), depth: \(z))")
            }

            switch ev.dispatchType {
            case .even(parameters: .constant(let x, let y, let z)),
                 .exact(parameters: .constant(let x, let y, let z)):
                sourceBuilder.add(line: "private static let gridSize\(idx) = MTLSize(width: \(x), height: \(y), depth: \(z))")
            default: ()
            }
        }

        // MARK: Balancing for class declarations
        sourceBuilder.popLevel()
        sourceBuilder.add(line: "}")

        return sourceBuilder.result
    }

}
