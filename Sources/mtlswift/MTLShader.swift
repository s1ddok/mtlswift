//
//  MTLShader.swift
//  mtlswift
//
//  Created by Andrey Volodin on 08/01/2019.
//

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
}
