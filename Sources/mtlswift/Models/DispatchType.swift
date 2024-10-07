public enum DispatchType {

    public enum DispatchParameters {
        case constant(x: Int, y: Int, z: Int)
        case over(argument: String)
        case provided
    }
    
    public enum IndirectParameters {
        case constant(offset: Int)
        case provided(default: Int)
    }

    case none
    case constant(x: Int, y: Int, z: Int)
    case even(parameters: DispatchParameters)
    case exact(parameters: DispatchParameters)
    case optimal(branchConstantIndex: Int, parameters: DispatchParameters)
    case indirect(parameters: IndirectParameters)
}
