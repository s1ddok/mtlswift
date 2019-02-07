//
//  MTLShader.swift
//  mtlswift
//
//  Created by Andrey Volodin on 08/01/2019.
//

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
            case buffer, texture, sampler, meta, stageIn, unknown
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
            className = "\(name.capitalizingFirstLetter)Encoder"
        }

        var swiftNameLookup: [String: String] = [:]
        var swiftTypeLookup: [String: String] = [:]
        for declaration in self.customDeclarations {
            if case .swiftParameterName(let oldName, let newName) = declaration {
                swiftNameLookup[oldName] = newName
            }

            if case .swiftParameterType(let parameter, let type) = declaration {
                swiftTypeLookup[parameter] = type
            }
        }

        // individual access levels are not supported for now
        // use global instead
        let parameters = self.parameters.compactMap { p -> MTLKernelEncoder.Parameter? in
            switch p.kind {
            case .sampler:
                let name = swiftNameLookup[p.name, default: p.name]
                if let type = swiftTypeLookup[p.name] {
                    print("WARNING: Swift Types are not available for sampler parameters, ignoring \(type)")
                }

                return MTLKernelEncoder.Parameter(name: name,
                                                  accessLevel: accessLevel,
                                                  swiftTypeName: "MTLSamplerState",
                                                  kind: .sampler,
                                                  index: p.index ?? -1,
                                                  isForceUnwrappedOptional: true,
                                                  defaultValueString: nil)
            case .texture:
                let name = swiftNameLookup[p.name, default: p.name]
                if let type = swiftTypeLookup[p.name] {
                    print("WARNING: Swift Types are not available for texture parameters, ignoring \(type)")
                }

                return MTLKernelEncoder.Parameter(name: name,
                                                  accessLevel: accessLevel,
                                                  swiftTypeName: "MTLTexture",
                                                  kind: .texture,
                                                  index: p.index ?? -1,
                                                  isForceUnwrappedOptional: true,
                                                  defaultValueString: nil)
            case .buffer:
                let name = swiftNameLookup[p.name, default: p.name]
                let type = swiftTypeLookup[p.name, default: "MTLBuffer"]

                return MTLKernelEncoder.Parameter(name: name,
                                                  accessLevel: accessLevel,
                                                  swiftTypeName: type,
                                                  kind: .buffer,
                                                  index: p.index ?? -1,
                                                  isForceUnwrappedOptional: true,
                                                  defaultValueString: nil)
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

        let threadgroupDeclaration = customDeclarations.first(of: .threadgroupSize(size: .provided)) ?? .threadgroupSize(size: .max)

        if case .threadgroupSize(let size) = threadgroupDeclaration,
           case .dispatchType(let type) = dispatchDeclaration {
            return MTLKernelEncoder(shaderName: self.name,
                                    swiftName: className,
                                    accessLevel: accessLevel,
                                    parameters: parameters,
                                    encodingVariants: [MTLKernelEncoder.EncodingVariant(dispatchType: type, threadgroupSize: size)])
        }

        return nil
    }
}
