public enum ThreadgroupSize {
    case max
    case executionWidth
    case constant(x: Int, y: Int, z: Int)
    case provided
}

public enum ThreadgroupMemoryLength {
    case providedTotal
    case providedPerThread
    case total(bytes: Int)
    case thread(bytes: Int)
}
