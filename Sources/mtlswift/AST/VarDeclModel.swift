public struct VarDeclModel: Model {
    public var id: Int64
    public var name: String
    public var typeDeclaration: String

    public var functionConstantType: ASTFunctionConstant.TypeDelcaration {
        if self.typeDeclaration.contains("_Bool") || self.typeDeclaration.contains("bool") {
            return .bool
        }

        if self.typeDeclaration.contains("ushort2") {
            return .ushort2
        }

        return .float
    }
}

public struct DeclRefModel: Model {
    public var usedIds: [Int64] = []
}
