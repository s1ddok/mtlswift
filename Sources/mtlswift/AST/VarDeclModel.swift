//
//  VarDeclModel.swift
//  mtlswift
//
//  Created by Andrey Volodin on 13/02/2019.
//

public struct VarDeclModel: Model {
    public var id: Int64
    public var name: String
    public var typeDeclaration: String

    public var functionConstantType: ASTFunctionConstant.TypeDelcaration {
        if self.typeDeclaration.contains("_Bool") {
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
