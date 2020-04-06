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
}
