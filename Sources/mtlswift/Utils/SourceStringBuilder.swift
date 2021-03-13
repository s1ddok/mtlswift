public class SourceStringBuilder {
    public var identationLevel = "  "

    fileprivate(set) public var currentIdentation = ""
    
    public func pushLevel() {
        currentIdentation += self.identationLevel
    }
    
    public func popLevel() {
        currentIdentation.removeLast(self.identationLevel.count)
    }
    
    public var result: String = ""
    
    public func begin() {
        result = "\n"
    }
    
    public func add(line: String) {
        result += self.currentIdentation + line + "\n"
    }

    public func blankLine() {
        result += "\n"
    }

    public func add(rawString: String) {
        result += rawString
    }
    
    public func sanitizeResult() {
        self.result = self.result
                          .replacingOccurrences(of: "float2", with: "SIMD2<Float>")
                          .replacingOccurrences(of: "float3", with: "SIMD3<Float>")
                          .replacingOccurrences(of: "float4", with: "SIMD4<Float>")
                                 
    }
}
