//
//  ASTNode.swift
//  mtlswift
//
//  Created by Andrey Volodin on 08/01/2019.
//

import Foundation

public class ASTNode {
    
    public enum Errors: Error {
        case parsingError
    }
    
    public weak var parent: ASTNode?
    public var children: [ASTNode] = []
    
    public var contentType: ContentType
    
    public var name: String = ""
    public var integerValue = 0
    
    public init(parsingString inputString: String) throws {
        
        let scanner = StringScanner(string: inputString)
        
        guard let prefix = scanner.readWordIfAny() else {
            throw Errors.parsingError
        }
        self.contentType = ContentType(rawValue: prefix)!
        
        switch self.contentType {
        case .functionDecl, .parmVarDecl:
            scanner.skipWhiteSpaces()
            scanner.skipHexIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipSlocIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipUsedStatement()
            scanner.skipWhiteSpaces()
            
            self.name = scanner.readWordIfAny() ?? "_"
        case .integerLiteral:
            scanner.skipWhiteSpaces()
            scanner.skipHexIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipSlocIfAny()
            scanner.skipWhiteSpaces()
            _ = scanner.readSingleQuotedTextIfAny()
            scanner.skipWhiteSpaces()
            
            guard let value = Int(scanner.leftString) else {
                fatalError(inputString)
            }
            
            self.integerValue = value
        default: return
        }
    }
    
    public func print(prefix: String) {
        Swift.print(prefix + self.contentType.rawValue)
        for child in self.children {
            child.print(prefix: prefix + "  ")
        }
    }
    
    public func extractMetalShaders() -> [MTLShader] {
        let extractedShaders = self.children.map { $0.tryExtractShader() }
        
        return extractedShaders.enumerated().flatMap { (offset, element) -> [MTLShader] in
            if element == nil {
                return self.children[offset].extractMetalShaders()
            } else {
                return [element!]
            }
        }
    }
    
    private func tryExtractShader() -> MTLShader? {
        guard self.contentType == .functionDecl
            && self.hasChildren(of: [.metalKernelAttr, .metalFragmentAttr, .metalVertexAttr])
            else {
                return nil
        }
        
        let parameterNode = self.children(of: .parmVarDecl)
        
        let parameters: [MTLShader.Parameter] = parameterNode.map { pn in
            var kind: MTLShader.Parameter.Kind = .unknown
            
            if pn.hasChildren(of: .metalSamplerIndexAttr) {
                kind = .sampler
            } else if pn.hasChildren(of: .metalTextureIndexAttr) {
                kind = .texture
            } else if pn.hasChildren(of: .metalBufferIndexAttr) {
                kind = .buffer
            } else if pn.hasChildren(of: .metalStageInAttr) {
                kind = .stageIn
            } else if pn.hasChildren(of: [.metalThreadPosGridAttr]) { // TODO: add all
                kind = .meta
            }
            
            let idx = pn.children(of: [.metalSamplerIndexAttr, .metalTextureIndexAttr, .metalBufferIndexAttr])
                .first?.children.first!.integerValue
            
            return MTLShader.Parameter(name: pn.name, kind: kind, index: idx)
        }
        
        let kind: MTLShader.Kind
        
        if self.hasChildren(of: .metalKernelAttr) {
            kind = .kernel
        } else if self.hasChildren(of: .metalFragmentAttr) {
            kind = .fragment
        } else {
            kind = .vertex
        }
        
        return MTLShader(name: self.name, kind: kind, parameters: parameters)
    }
    
    public func hasChildren(of type: ContentType) -> Bool {
        return !self.children(of: type).isEmpty
    }
    
    public func children(of type: ContentType) -> [ASTNode] {
        return self.children.filter { $0.contentType == type }
    }
    
    public func hasChildren(of types: [ContentType]) -> Bool {
        return !self.children(of: types).isEmpty
    }
    
    public func children(of types: [ContentType]) -> [ASTNode] {
        return self.children.filter { types.contains($0.contentType) }
    }
}
