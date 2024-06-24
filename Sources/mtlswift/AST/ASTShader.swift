extension String {
    var capitalizingFirstLetter: String {
        guard !self.isEmpty else { return self }
        
        return String(self.first!).uppercased() + String(self.dropFirst())
    }
}

public struct ASTShader {
    public enum Kind {
        case kernel, fragment, vertex
    }
    
    public struct Parameter {
        public enum Kind {
            case buffer, texture, sampler, threadgroupMemory, meta, stageIn, unknown
        }
        
        public var name: String
        public var kind: Kind
        public var index: Int?
        
        public var description: String {
            return "parameter \(name): \(kind)(\(index ?? -1))"
        }
    }
    
    public var name: String
    public var kind: Kind
    public var parameters: [Parameter]
    public var customDeclarations: [CustomDeclaration]
    public var usedConstants: [ASTFunctionConstant]
    
    public var description: String {
        return """
        MTLShader
        name: \(name)
        kind: \(kind)
        parameters:
        \(self.parameters.map { $0.description })
"""
    }

    public func kernelEncoder() -> MTLKernelEncoder? {
        var accessLevel: AccessLevel = .internal
        if let accessLevelDeclaration = self.customDeclarations.first(of: .accessLevel(level: accessLevel)),
            case .accessLevel(let level) = accessLevelDeclaration {
            accessLevel = level
        }

        let className: String
        if let nameDeclaration = self.customDeclarations.first(of: .swiftName(name: "")),
            case .swiftName(let name) = nameDeclaration {
            className = name
        } else {
            className = "\(name.capitalizingFirstLetter)"
        }

        var swiftNameLookup: [String: String] = [:]
        var swiftTypeLookup: [String: String] = [:]
        var inPlaceTextureNameMappings = [MTLKernelEncoder.InPlaceTextureNameMapping]()
        for declaration in self.customDeclarations {
            if case let .swiftParameterName(oldName, newName) = declaration {
                swiftNameLookup[oldName] = newName
            }

            if case let .swiftParameterType(parameter, type) = declaration {
                swiftTypeLookup[parameter] = type
            }
            if case let .inPlaceTexture(source, destination, inPlace) = declaration {
                inPlaceTextureNameMappings.append(.init(source: source, destination: destination, inPlace: inPlace))
            }
        }

        // individual access levels are not supported for now
        // use global instead
        var threadgroupMemoryCalculatiosn: [MTLKernelEncoder.ThreadgroupMemoryLengthCalculation] = []
        let parameters = self.parameters.compactMap { p -> MTLKernelEncoder.Parameter? in
            switch p.kind {
            case .sampler:
                let name = swiftNameLookup[p.name, default: p.name]
                if let type = swiftTypeLookup[p.name] {
                    print("WARNING: Swift Types are not available for sampler parameters, ignoring \(type)")
                }

                return MTLKernelEncoder.Parameter(name: name,
                                                  swiftTypeName: "MTLSamplerState",
                                                  kind: .sampler,
                                                  index: p.index ?? -1,
                                                  defaultValueString: nil)
            case .texture:
                let name = swiftNameLookup[p.name, default: p.name]
                var type = swiftTypeLookup[p.name] ?? "MTLTexture"

                if type != "MTLTexture" && type != "MTLTexture?" {
                    print("WARNING: Swift Types are not available for texture parameters, ignoring \(type)")
                    type = "MTLTexture"
                }
                
                return MTLKernelEncoder.Parameter(name: name,
                                                  swiftTypeName: type,
                                                  kind: .texture,
                                                  index: p.index ?? -1,
                                                  defaultValueString: nil)
            case .buffer:
                let name = swiftNameLookup[p.name, default: p.name]
                let type = swiftTypeLookup[p.name, default: "MTLBuffer"]

                return MTLKernelEncoder.Parameter(name: name,
                                                  swiftTypeName: type,
                                                  kind: .buffer,
                                                  index: p.index ?? -1,
                                                  defaultValueString: nil)
            case .threadgroupMemory:
                let name = swiftNameLookup[p.name, default: p.name]
                let correspondingSetting: ThreadgroupMemoryLength = self.customDeclarations.lazy.compactMap {
                    if case .threadgroupMemory(p.index, let setup) = $0 {
                        return setup
                    }
                    return nil
                }.first ?? .providedTotal

                switch correspondingSetting {
                case .providedTotal:
                    return MTLKernelEncoder.Parameter(name: name + "TotalLength",
                                                      swiftTypeName: "Int",
                                                      kind: .threadgroupMemory,
                                                      index: p.index ?? -1)
                case .providedPerThread:
                    let parameterName = name + "PerThreadLength"
                    threadgroupMemoryCalculatiosn.append(.parameterPerThread(index: p.index ?? -1, parameterName: parameterName))
                    return MTLKernelEncoder.Parameter(name: parameterName,
                                                      swiftTypeName: "Int",
                                                      kind: .threadgroupMemory,
                                                      index: p.index ?? -1)
                case .total(let bytes):
                    // side effect of this closure
                    threadgroupMemoryCalculatiosn.append(.total(index: p.index ?? -1, bytes: bytes))
                    return nil
                case .thread(let bytes):
                    // side effect of this closure
                    threadgroupMemoryCalculatiosn.append(.perThread(index: p.index ?? -1, bytes: bytes))
                    return nil
                }
            default:
                if let type = swiftTypeLookup[p.name] {
                    print("WARNING: Swift Types are only available for buffer parameters, ignoring \(type)")
                }

                return nil
            }
        }

        let dispatchDeclaration = customDeclarations.first(where: { d -> Bool in
            if case .dispatchType(_) = d { return true } else { return false }
        }) ?? .dispatchType(type: .none)

        var branchingConstant: ASTFunctionConstant? = nil
        var constants = self.usedConstants
        if case .dispatchType(type: .optimal(let index, _)) = dispatchDeclaration {
            branchingConstant = self.usedConstants.first { $0.index == index }

            // TODO: check that constant is used and it is bool

            constants.removeAll { $0.index == index }
        }

        let threadgroupDeclaration = customDeclarations.first(of: .threadgroupSize(size: .provided)) ?? .threadgroupSize(size: .max)

        if case .threadgroupSize(let size) = threadgroupDeclaration,
           case .dispatchType(let type) = dispatchDeclaration {
            return MTLKernelEncoder(shaderName: self.name,
                                    swiftName: className,
                                    accessLevel: accessLevel,
                                    parameters: parameters,
                                    encodingVariants: [MTLKernelEncoder.EncodingVariant(dispatchType: type, threadgroupSize: size)],
                                    usedConstants: constants,
                                    branchingConstant: branchingConstant,
                                    threadgroupMemoryCalculations: threadgroupMemoryCalculatiosn,
                                    inPlaceTextureNameMappings: inPlaceTextureNameMappings)
        }

        return nil
    }
}
