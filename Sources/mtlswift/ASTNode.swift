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
    
    public var model: Any? = nil
    
    public var stringValue: String? = nil
    public var integerValue: Int? = nil
    
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
            
            self.stringValue = scanner.readWordIfAny()
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
        case .textComment:
            scanner.skipWhiteSpaces()
            scanner.skipHexIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipSlocIfAny()
            scanner.skipWhiteSpaces()
            
            if let text = scanner.readTextAttribute() {
                self.stringValue = text
            }
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
            } else if pn.hasChildren(of: [.metalThreadPosGridAttr,
                                          .metalThreadPosGroupAttr,
                                          .metalThreadsPerGroupAttr,
                                          .metalThreadIndexGroupAttr]) { // TODO: add all
                kind = .meta
            }
            
            let idx = pn.children(of: [.metalSamplerIndexAttr, .metalTextureIndexAttr, .metalBufferIndexAttr])
                .first?.children.first!.integerValue!
            
            return MTLShader.Parameter(name: pn.stringValue ?? "_", kind: kind, index: idx)
        }
        
        let kind: MTLShader.Kind
        
        if self.hasChildren(of: .metalKernelAttr) {
            kind = .kernel
        } else if self.hasChildren(of: .metalFragmentAttr) {
            kind = .fragment
        } else {
            kind = .vertex
        }
        
        var declarations: [CustomDeclaration] = []
        if let fullComment = self.children(of: .fullComment).first {
            for paragraph in fullComment.children(of: .paragraphComment) {
                textLoop: for text in paragraph.children(of: .textComment) {
                    guard let rawString = text.stringValue else {
                        continue textLoop
                    }
                    
                    let scanner = StringScanner(string: rawString)
                    scanner.skipWhiteSpaces()
                        
                    guard scanner.skip(exact: CustomDeclaration.declarationPrefix),
                          let declaration = CustomDeclaration(rawString: scanner.leftString) else {
                        continue textLoop
                    }
                    
                    if case .ignore = declaration {
                        return nil
                    }
                    declarations.append(declaration)
                }
            }
        }
        

        return MTLShader(name: self.stringValue!,
                         kind: kind,
                         parameters: parameters,
                         customDeclarations: declarations)
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
