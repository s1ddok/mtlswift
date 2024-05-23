public enum DispatchType {

    public enum DispatchParameters {
        case constant(x: Int, y: Int, z: Int)
        case over(argument: String)
        case provided
    }

    case none
    case constant(x: Int, y: Int, z: Int)
    case even(parameters: DispatchParameters)
    case exact(parameters: DispatchParameters)
    case optimal(branchConstantIndex: Int, parameters: DispatchParameters)
}
