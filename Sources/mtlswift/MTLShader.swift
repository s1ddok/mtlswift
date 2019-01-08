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
        
        builder.add(line:"public class \(name.capitalizingFirstLetter)Encoder {")
        builder.pushLevel()
        builder.add(line: "fileprivate let pipelineState: MTLComputePipelineState")
        
        builder.add(line: "")
        
        for parameter in self.parameters {
            let swiftType: String
            
            switch parameter.kind {
            case .buffer: swiftType = "MTLBuffer"
            case .sampler: swiftType = "MTLSamplerState"
            case .texture: swiftType = "MTLTexture"
            default: continue
            }
            builder.add(line: "public var \(parameter.name): \(swiftType)? = nil")
            
            switch parameter.kind {
            case .buffer:
                builder.add(line: "public var \(parameter.name)Offset: Int = 0")
            default: continue
            }
        }
        
        builder.add(line: "")
        
        builder.add(line: "public init(library: MTLLibrary) throws {")
        builder.pushLevel()
        
        builder.add(line: "self.pipelineState = try library.computePipelineState(function: \"\(self.name)\")")
        
        builder.popLevel()
        builder.add(line: "}")
        
        builder.add(line: "")
        
        builder.add(line: "func encode(using encoder: MTLComputeCommandEncoder) {")
        builder.pushLevel()
        
        for parameter in self.parameters {
            switch parameter.kind {
            case .buffer:
                builder.add(line: "encoder.setBuffer(self.\(parameter.name), offset: self.\(parameter.name)Offset, index: \(parameter.index!))")
            case .sampler:
                builder.add(line: "encoder.setSamplerState(self.\(parameter.name), index: \(parameter.index!))")
            case .texture:
                builder.add(line: "encoder.setTexture(self.\(parameter.name), index: \(parameter.index!))")
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
