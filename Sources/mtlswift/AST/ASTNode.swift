import Foundation

public protocol Model { }

public class ASTNode {
    
    public enum Errors: Error {
        case parsingError
        case contentTypeCreationFailed
    }
    
    public weak var parent: ASTNode?
    public var children: [ASTNode] = []
    
    public var contentType: ContentType
    
    public var model: Model? = nil
    
    public var stringValue: String? = nil
    public var integerValue: Int? = nil
    
    public init(parsingString inputString: String) throws {
        let scanner = StringScanner(string: inputString)
        
        guard let prefix = scanner.readWord()
        else { throw Errors.parsingError }

        guard let contentType = ContentType(rawValue: prefix)
        else {
            self.contentType = .unknown
            Swift.print("Warning: failed to parse \(inputString)")
            return
        }
        self.contentType = contentType
        
        switch self.contentType {
        case .metalHostNameAttr:
            scanner.skipWhiteSpaces()
            scanner.skipHexIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipSlocIfAny()
            scanner.skipWhiteSpaces()
            
            let namespaceName = scanner.readString()
            self.stringValue = namespaceName
        case .namespaceDecl:
            scanner.skipWhiteSpaces()
            scanner.skipHexIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipSlocIfAny()
            scanner.skipWhiteSpaces()

            let namespaceName = scanner.readWord()
            self.stringValue = namespaceName
        case .varDecl:
            scanner.skipWhiteSpaces()

            guard let hex = scanner.readWord() else {
                Swift.print("Missing hex in \(inputString)")
                break
            }

            scanner.skipWhiteSpaces()
            scanner.skipSlocIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipUsedStatement()
            scanner.skipWhiteSpaces()

            if scanner.skip(exact: "referenced")
            || scanner.skip(exact: "referenced value")
            || scanner.skip(exact: "referenced next_expected")
            || scanner.skip(exact: "referenced swapped")
            || scanner.skip(exact: "referenced t")
            || scanner.skip(exact: "invalid") {
                break
            }

            guard let varName = scanner.readWord() else {
                Swift.print("Parsing error in \(inputString)")
                break
            }

            scanner.skipWhiteSpaces()

            guard let typeDeclaration = scanner.readSingleQuotedTextIfAny() else {
                Swift.print("Parsing error in \(inputString)")
                break
            }

            let varDeclModel = VarDeclModel(id: Int64(hex.dropFirst(2), radix: 16)!,
                                            name: varName,
                                            typeDeclaration: typeDeclaration)
            self.model = varDeclModel
        case .functionDecl, .parmVarDecl:
            scanner.skipWhiteSpaces()
            scanner.skipHexIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipSlocIfAny()
            scanner.skipWhiteSpaces()
            scanner.skipUsedStatement()
            scanner.skipWhiteSpaces()
            scanner.skipInvalidStatement()
            scanner.skipWhiteSpaces()
            
            self.stringValue = scanner.readWord()
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
        case .declRefExpr:
            scanner.skipWhiteSpaces()
            scanner.skipHexIfAny()

            let usedIds = try scanner.readAll(pattern: "0[xX][0-9a-fA-F]+")
            self.model = DeclRefModel(usedIds: usedIds.map { Int64($0.dropFirst(2), radix: 16)! })
        default: ()
        }
    }
    
    public func print(prefix: String) {
        Swift.print(prefix + self.contentType.rawValue)
        for child in self.children {
            child.print(prefix: prefix + "  ")
        }
    }

    public func hasUsageOfVar(with id: Int64) -> Bool {
        if let declRefModel = self.model as? DeclRefModel,
           declRefModel.usedIds.contains(id) {
            return true
        }

        for child in self.children {
            if child.hasUsageOfVar(with: id) {
                return true
            }
        }

        return false
    }

    public func extractMetalFunctionConstants() -> [ASTFunctionConstant] {
        var retVal: [ASTFunctionConstant] = []

        if let fc = self.tryExtractFunctionConstant() {
            retVal.append(fc)
        }

        for child in self.children {
            retVal.append(contentsOf: child.extractMetalFunctionConstants())
        }

        return retVal
    }

    public func tryExtractFunctionConstant() -> ASTFunctionConstant? {
        guard self.contentType == .varDecl,
              let model = self.model as? VarDeclModel,
              let attr = self.children.first(where: { $0.contentType == .metalFunctionConstantAttr }),
              let idx = attr.children.first?.integerValue
        else { return nil }

        return ASTFunctionConstant(id: model.id,
                                   name: model.name,
                                   index: idx,
                                   type: model.functionConstantType)
    }
    
    public func extractMetalShaders(constants: [ASTFunctionConstant]) -> [ASTShader] {
        let extractedShaders = self.children.map { $0.tryExtractShader(constants: constants) }
        
        return extractedShaders.enumerated().flatMap { (offset, element) -> [ASTShader] in
            if element == nil {
                return self.children[offset].extractMetalShaders(constants: constants)
            } else {
                return [element!]
            }
        }
    }
    
    private func tryExtractShader(constants: [ASTFunctionConstant]) -> ASTShader? {
        guard self.contentType == .functionDecl
           && self.hasChildren(of: [.metalKernelAttr,
                                    .metalFragmentAttr,
                                    .metalVertexAttr])
        else { return nil }
        
        
        let hostName = self.children(of: .metalHostNameAttr).first?.stringValue

        let parameterNode = self.children(of: .parmVarDecl)
        
        // this is to filter the parent of template kernels
        if parameterNode.filter({ $0.stringValue == "referenced" }).count > 1 && hostName == nil {
            return nil
        }
        var declarations: [CustomDeclaration] = []

        let parameters: [ASTShader.Parameter] = parameterNode.map { pn in
            var kind: ASTShader.Parameter.Kind = .unknown

            if pn.hasChildren(of: .metalSamplerIndexAttr) {
                kind = .sampler
            } else if pn.hasChildren(of: .metalTextureIndexAttr) {
                kind = .texture
                if let _ = pn.children.first(where: { $0.contentType == .metalFunctionConstantAttr }) {
                    declarations.append(.swiftParameterType(parameter: pn.stringValue ?? "_",
                                                            type: "MTLTexture?"))
                }
            } else if pn.hasChildren(of: .metalBufferIndexAttr) {
                kind = .buffer
            } else if pn.hasChildren(of: .metalLocalIndexAttr) {
                kind = .threadgroupMemory
            } else if pn.hasChildren(of: .metalStageInAttr) {
                kind = .stageIn
            } else if pn.hasChildren(of: [.metalThreadPosGridAttr,
                                          .metalThreadPosGroupAttr,
                                          .metalThreadsPerGroupAttr,
                                          .metalThreadsPerGridAttr,
                                          .metalThreadIndexGroupAttr]) { // TODO: add all
                kind = .meta
            }

            let idx = pn.children(of: [.metalSamplerIndexAttr,
                                       .metalTextureIndexAttr,
                                       .metalBufferIndexAttr,
                                       .metalLocalIndexAttr])
                        .first?.children.first!.integerValue!

            return ASTShader.Parameter(name: pn.stringValue ?? "_", kind: kind, index: idx, optional: pn.hasChildren(of: .metalFunctionConstantAttr))
        }

        let kind: ASTShader.Kind
        
        if self.hasChildren(of: .metalKernelAttr) {
            kind = .kernel
        } else if self.hasChildren(of: .metalFragmentAttr) {
            kind = .fragment
        } else {
            kind = .vertex
        }

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

        let usedConstants = constants.filter { self.hasUsageOfVar(with: $0.id) }

        return ASTShader(name: hostName ?? self.stringValue!,
                         kind: kind,
                         parameters: parameters,
                         customDeclarations: declarations,
                         usedConstants: usedConstants)
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
