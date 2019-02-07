//
//  MTLKernelEncoder.swift
//  Clang
//
//  Created by Andrey Volodin on 07/02/2019.
//

public struct MTLKernelEncoder {

    public struct Parameter {
        public enum Kind {
            case texture, buffer, sampler
        }
        public var name: String
        public var accessLevel: AccessLevel
        public var swiftTypeName: String

        public var kind: Kind
        public var index: Int

        public var isForceUnwrappedOptional: Bool = true
        public var defaultValueString: String? = nil
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

    public var shaderString: String {
        let sourceBuilder = SourceStringBuilder()
        sourceBuilder.begin()

        sourceBuilder.add(line: "\(self.accessLevel.rawValue) class \(self.swiftName) {")
        sourceBuilder.blankLine()
        sourceBuilder.pushLevel()

        for parameter in self.parameters {
            sourceBuilder.add(line: "\(self.accessLevel.rawValue) var \(parameter.name): \(parameter.swiftTypeName)\(parameter.isForceUnwrappedOptional ? "!" : "?")")
        }

        sourceBuilder.blankLine()
        sourceBuilder.add(line: "\(self.accessLevel.rawValue) let pipelineState: MTLComputePipelineState")
        sourceBuilder.blankLine()

        // MARK: Generate inits
        sourceBuilder.add(line: "\(self.accessLevel.rawValue) init(library: MTLLibrary) throws {")
        sourceBuilder.pushLevel()

        sourceBuilder.add(line: "self.pipelineState = try library.computePipelineState(function: \"\(self.shaderName)\")")

        // MARK: Balancing for init
        sourceBuilder.popLevel()
        sourceBuilder.add(line: "}")

        sourceBuilder.blankLine()

        // MARK: Generate encoding
        for (idx, ev) in self.encodingVariants.enumerated() {
            var threadgroupParameterString = ""
            var threadgroupExpressionString = ""

            switch ev.threadgroupSize {
            case .provided:
                threadgroupParameterString = ", threadgroupSize: MTLSize"
                threadgroupExpressionString = ", threadgroupSize: threadgroupSize"
            case .max:
                threadgroupExpressionString = ", threadgroupSize: self.pipelineState.max2dThreadgroupSize"
            case .executionWidth:
                threadgroupExpressionString = ", threadgroupSize: self.pipelineState.executionWidthThreadgroupSize"
            case .constant(_, _, _):
                threadgroupExpressionString = ", threadgroupSize: \(self.swiftName).threadgroupSize\(idx)"
            }

            var gridSizeParameterString = ""
            switch ev.dispatchType {
            case .exact(parameters: .provided),
                 .even(parameters: .provided):
                gridSizeParameterString = ", gridSize: MTLSize"
            default: ()
            }

            sourceBuilder.add(line: "\(self.accessLevel.rawValue) func encode(using encoder: MTLComputeCommandEncoder\(gridSizeParameterString)\(threadgroupParameterString)) {")
            sourceBuilder.pushLevel()

            for parameter in self.parameters {
                switch parameter.kind {
                case .buffer:
                    if parameter.swiftTypeName == "MTLBuffer" {
                        sourceBuilder.add(line: "encoder.setBuffer(self.\(parameter.name), offset: 0, index: \(parameter.index))")
                    } else {
                        sourceBuilder.add(line: "if let parameter = self.\(parameter.name) {")
                        sourceBuilder.pushLevel()
                        sourceBuilder.add(line: "encoder.set(parameter, at: \(parameter.index))")
                        sourceBuilder.popLevel()
                        sourceBuilder.add(line: "} else {")
                        sourceBuilder.pushLevel()
                        sourceBuilder.add(line: "encoder.setBuffer(nil, offset: 0, index: \(parameter.index))")
                        sourceBuilder.popLevel()
                        sourceBuilder.add(line: "}")
                    }
                case .texture:
                    sourceBuilder.add(line: "encoder.setTexture(self.\(parameter.name), index: \(parameter.index))")
                case .sampler:
                    sourceBuilder.add(line: "encoder.setSamplerState(self.\(parameter.name), index: \(parameter.index))")
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
                   targetParameter.kind == .texture {
                    sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, covering: \(targetParameter.name)!.size\(threadgroupExpressionString))")
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
                    targetParameter.kind == .texture {
                    sourceBuilder.add(line: "encoder.dispatch2d(state: self.pipelineState, exactly: \(targetParameter.name)!.size\(threadgroupExpressionString))")
                } else {
                    fatalError("Could not generate dispatching over parameter \(argument)")
                }
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
