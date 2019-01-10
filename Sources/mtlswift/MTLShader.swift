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

public struct MTLShader {
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
    
    public func generateSwiftSource(in builder: SourceStringBuilder) {
        guard self.kind == .kernel else {
            print("At this point only kernel generation is implemented")
            return
        }
        
        var accessLevel: CustomDeclaration.AccessLevel = .internal
        if let accessLevelDeclaration = self.customDeclarations.first(where: { d -> Bool in
            if case .accessLevel(_) = d {
                return true
            } else {
                return false
            }
        }) {
            if case .accessLevel(let level) = accessLevelDeclaration {
                accessLevel = level
            }
        }
        
        if let nameDeclaration = self.customDeclarations.first(where: { d -> Bool in
            if case .swiftName(_) = d {
                return true
            } else {
                return false
            }
        }) {
            if case .swiftName(let name) = nameDeclaration {
                builder.add(line:"\(accessLevel.rawValue) class \(name) {")
            }
        } else {
            builder.add(line:"\(accessLevel.rawValue) class \(name.capitalizingFirstLetter)Encoder {")
        }
        builder.pushLevel()
        builder.add(line: "\(accessLevel.rawValue) let pipelineState: MTLComputePipelineState")
        
        builder.add(line: "")
        
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
        
        for parameter in self.parameters {
            var swiftType = swiftTypeLookup[parameter.name]
            
            let hasLookup = swiftType != nil
            
            switch parameter.kind {
            case .buffer:
                if !hasLookup {
                    swiftType = "MTLBuffer"
                }
            case .sampler:
                if swiftType != nil {
                    print("WARNING: Swift Types are not available for sampler parameters, ignoring \(swiftType!)")
                }
                swiftType = "MTLSamplerState"
            case .texture:
                if swiftType != nil {
                    print("WARNING: Swift Types are not available for texture parameters, ignoring \(swiftType!)")
                }
                swiftType = "MTLTexture"
            default:
                if swiftType != nil {
                    print("WARNING: Swift Types are only available for buffer parameters, ignoring \(swiftType!)")
                }
                continue
            }
            builder.add(line: "\(accessLevel.rawValue) var \(swiftNameLookup[parameter.name] ?? parameter.name): \(swiftType!)? = nil")
            
            switch parameter.kind {
            case .buffer:
                if !hasLookup {
                    builder.add(line: "\(accessLevel.rawValue) var \(swiftNameLookup[parameter.name] ?? parameter.name)Offset: Int = 0")
                }
            default: continue
            }
        }
        
        builder.add(line: "")
        
        builder.add(line: "\(accessLevel.rawValue) init(library: MTLLibrary) throws {")
        builder.pushLevel()
        
        builder.add(line: "self.pipelineState = try library.computePipelineState(function: \"\(self.name)\")")
        
        builder.popLevel()
        builder.add(line: "}")
        
        builder.add(line: "")
        
        builder.add(line: "\(accessLevel.rawValue) func encode(using encoder: MTLComputeCommandEncoder) {")
        builder.pushLevel()
        
        for parameter in self.parameters {
            switch parameter.kind {
            case .buffer:
                if let _ = swiftTypeLookup[parameter.name] {
                    builder.add(line: "if let _\(swiftNameLookup[parameter.name] ?? parameter.name) = self.\(swiftNameLookup[parameter.name] ?? parameter.name) {")
                    builder.pushLevel()
                    builder.add(line: "encoder.set(_\(swiftNameLookup[parameter.name] ?? parameter.name), at: \(parameter.index!))")
                    builder.popLevel()
                    builder.add(line: "} else {")
                    builder.pushLevel()
                    builder.add(line: "encoder.setBuffer(nil, offset: 0, index: \(parameter.index!))")
                    builder.popLevel()
                    builder.add(line: "}")
                } else {
                    builder.add(line: "encoder.setBuffer(self.\(swiftNameLookup[parameter.name] ?? parameter.name), offset: self.\(parameter.name)Offset, index: \(parameter.index!))")
                }
                
            case .sampler:
                builder.add(line: "encoder.setSamplerState(self.\(swiftNameLookup[parameter.name] ?? parameter.name), index: \(parameter.index!))")
            case .texture:
                builder.add(line: "encoder.setTexture(self.\(swiftNameLookup[parameter.name] ?? parameter.name), index: \(parameter.index!))")
            default: continue
            }
        }
        
        builder.add(line: "")
        
        builder.add(line: "encoder.setComputePipelineState(self.pipelineState)")
        
        builder.popLevel()
        builder.add(line: "}")
        
        builder.add(line: "")
        
        builder.popLevel()
        builder.add(line: "}")
        
        builder.add(line: "")
    }
}
