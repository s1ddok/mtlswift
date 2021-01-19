public struct ASTFunctionConstant {
    public enum TypeDelcaration {
        // TODO: Support all types
        case bool, ushort2, float, half, int, uint

        public var swiftTypeDelcaration: String {
            switch self {
            case .bool:
                return "Bool"
            case .ushort2:
                return "(UInt16, UInt16)"
            case .float:
                return "Float"
            case .half:
                return "UInt16"
            case .int:
                return "Int32"
            case .uint:
                return "UInt32"
            }
        }
    }

    public var id: Int64
    public var name: String
    public var index: Int
    public var type: TypeDelcaration
}
