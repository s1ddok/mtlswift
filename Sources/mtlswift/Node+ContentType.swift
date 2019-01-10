//
//  Node+ContentType.swift
//  Clang
//
//  Created by Andrey Volodin on 07/01/2019.
//

public extension ASTNode {
    public enum ContentType: String {
        case varTemplateSpecializationDecl = "VarTemplateSpecializationDecl"
        case typeAliasTemplateDecl = "TypeAliasTemplateDecl"
        case conditionalOperator = "ConditionalOperator"
        case templateTypeParmDecl = "TemplateTypeParmDecl"
        case enumConstantDecl = "EnumConstantDecl"
        case unresolvedMemberExpr = "UnresolvedMemberExpr"
        case cXXFunctionalCastExpr = "CXXFunctionalCastExpr"
        case opaqueValueExpr = "OpaqueValueExpr"
        case qualType = "QualType"
        case metalTextureIndexAttr = "MetalTextureIndexAttr"
        case metalSamplerIndexAttr = "MetalSamplerIndexAttr"
        case typedef = "Typedef"
        case builtinType = "BuiltinType"
        case stringLiteral = "StringLiteral"
        case substTemplateTypeParmType = "SubstTemplateTypeParmType"
        case exprWithCleanups = "ExprWithCleanups"
        case cStyleCastExpr = "CStyleCastExpr"
        case dependentSizedExtVectorType = "DependentSizedExtVectorType"
        case `private` = "private"
        case memberExpr = "MemberExpr"
        case cXXDefaultArgExpr = "CXXDefaultArgExpr"
        case cXXScalarValueInitExpr = "CXXScalarValueInitExpr"
        case translationUnitDecl = "TranslationUnitDecl"
        case asmLabelAttr = "AsmLabelAttr"
        case forStmt = "ForStmt"
        case friendDecl = "FriendDecl"
        case functionTemplateDecl = "FunctionTemplateDecl"
        case unresolvedLookupExpr = "UnresolvedLookupExpr"
        case templateArgument = "TemplateArgument"
        case arraySubscriptExpr = "ArraySubscriptExpr"
        case typedefDecl = "TypedefDecl"
        case templateSpecializationType = "TemplateSpecializationType"
        case `public` = "public"
        case continueStmt = "ContinueStmt"
        case builtinTemplateDecl = "BuiltinTemplateDecl"
        case metalPositionAttr = "MetalPositionAttr"
        case metalFlatAttr = "MetalFlatAttr"
        case metalStageInAttr = "MetalStageInAttr"
        case metalFunctionConstantAttr = "MetalFunctionConstantAttr"
        case metalLocalIndexAttr = "MetalLocalIndexAttr"
        case metalThreadsPerGroupAttr = "MetalThreadsPerGroupAttr"
        case metalThreadIndexGroupAttr = "MetalThreadIndexGroupAttr"
        case metalThreadPosGroupAttr = "MetalThreadPosGroupAttr"    
        case templateTypeParmType = "TemplateTypeParmType"
        case cXXCtorInitializer = "CXXCtorInitializer"
        case typedefType = "TypedefType"
        case parenListExpr = "ParenListExpr"
        case cXXRecord = "CXXRecord"
        case cXXRecordDecl = "CXXRecordDecl"
        case enumDecl = "EnumDecl"
        case alignedAttr = "AlignedAttr"
        case extVectorType = "ExtVectorType"
        case unresolvedUsingValueDecl = "UnresolvedUsingValueDecl"
        case enumType = "EnumType"
        case packExpansionExpr = "PackExpansionExpr"
        case recordType = "RecordType"
        case cXXBoolLiteralExpr = "CXXBoolLiteralExpr"
        case classTemplateDecl = "ClassTemplateDecl"
        case classTemplateSpecializationDecl = "ClassTemplateSpecializationDecl"
        case pureAttr = "PureAttr"
        case parenExpr = "ParenExpr"
        case cXXNullPtrLiteralExpr = "CXXNullPtrLiteralExpr"
        case varDecl = "VarDecl"
        case binaryOperator = "BinaryOperator"
        case parmVarDecl = "ParmVarDecl"
        case cXXOperatorCallExpr = "CXXOperatorCallExpr"
        case floatingLiteral = "FloatingLiteral"
        case integerLiteral = "IntegerLiteral"
        case nonTypeTemplateParmDecl = "NonTypeTemplateParmDecl"
        case cXXDestructorDecl = "CXXDestructorDecl"
        case pointerType = "PointerType"
        case templateTypeParm = "TemplateTypeParm"
        case initListExpr = "InitListExpr"
        case classTemplatePartialSpecializationDecl = "ClassTemplatePartialSpecializationDecl"
        case substNonTypeTemplateParmExpr = "SubstNonTypeTemplateParmExpr"
        case templateTemplateParmDecl = "TemplateTemplateParmDecl"
        case cXXUnresolvedConstructExpr = "CXXUnresolvedConstructExpr"
        case alwaysInlineAttr = "AlwaysInlineAttr"
        case decltypeType = "DecltypeType"
        case returnStmt = "ReturnStmt"
        case deprecatedAttr = "DeprecatedAttr"
        case cXXTemporaryObjectExpr = "CXXTemporaryObjectExpr"
        case extVectorElementExpr = "ExtVectorElementExpr"
        case namespaceAliasDecl = "NamespaceAliasDecl"
        case unaryTransformType = "UnaryTransformType"
        case varTemplateDecl = "VarTemplateDecl"
        case linkageSpecDecl = "LinkageSpecDecl"
        case metalThreadPosGridAttr = "MetalThreadPosGridAttr"
        case metalKernelAttr = "MetalKernelAttr"
        case metalFragmentAttr = "MetalFragmentAttr"
        case metalVertexAttr = "MetalVertexAttr"
        case metalVertexIdAttr = "MetalVertexIdAttr"
        case compoundStmt = "CompoundStmt"
        case enableIfAttr = "EnableIfAttr"
        case namespaceDecl = "NamespaceDecl"
        case asTypeExpr = "AsTypeExpr"
        case declRefExpr = "DeclRefExpr"
        case arrayInitLoopExpr = "ArrayInitLoopExpr"
        case cXXConversionDecl = "CXXConversionDecl"
        case function = "Function"
        case classTemplateSpecialization = "ClassTemplateSpecialization"
        case lValueReferenceType = "LValueReferenceType"
        case unaryOperator = "UnaryOperator"
        case cXXMethodDecl = "CXXMethodDecl"
        case cXXStaticCastExpr = "CXXStaticCastExpr"
        case materializeTemporaryExpr = "MaterializeTemporaryExpr"
        case typeAliasDecl = "TypeAliasDecl"
        case cXXConstCastExpr = "CXXConstCastExpr"
        case namespace = "Namespace"
        case sizeOfPackExpr = "SizeOfPackExpr"
        case compoundAssignOperator = "CompoundAssignOperator"
        case metalAsTypeCastExpr = "MetalAsTypeCastExpr"
        case injectedClassNameType = "InjectedClassNameType"
        case declStmt = "DeclStmt"
        case dependentScopeDeclRefExpr = "DependentScopeDeclRefExpr"
        case elaboratedType = "ElaboratedType"
        case noThrowAttr = "NoThrowAttr"
        case cXXConstructExpr = "CXXConstructExpr"
        case textComment = "TextComment"
        case ifStmt = "IfStmt"
        case cXXThisExpr = "CXXThisExpr"
        case metalBufferIndexAttr = "MetalBufferIndexAttr"
        case constAttr = "ConstAttr"
        case paragraphComment = "ParagraphComment"
        case original = "original"
        case unaryExprOrTypeTraitExpr = "UnaryExprOrTypeTraitExpr"
        case accessSpecDecl = "AccessSpecDecl"
        case callExpr = "CallExpr"
        case fullComment = "FullComment"
        case usingDirectiveDecl = "UsingDirectiveDecl"
        case implicitCastExpr = "ImplicitCastExpr"
        case dependentNameType = "DependentNameType"
        case functionDecl = "FunctionDecl"
        case cXXDependentScopeMemberExpr = "CXXDependentScopeMemberExpr"
        case cXXMemberCallExpr = "CXXMemberCallExpr"
        case cXXConstructorDecl = "CXXConstructorDecl"
        case `enum` = "Enum"
        case fieldDecl = "FieldDecl"
        case metalVectorInitExpr = "MetalVectorInitExpr"
        case staticAssertDecl = "StaticAssertDecl"
    }
}
