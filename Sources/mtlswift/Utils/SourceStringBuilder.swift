public class SourceStringBuilder {
    public var identationLevel = "  "

    fileprivate(set) public var currentIdentation = ""
    
    public func pushLevel() {
        self.currentIdentation += self.identationLevel
    }
    
    public func popLevel() {
        self.currentIdentation.removeLast(self.identationLevel.count)
    }
    
    public var result: String = ""
    
    public func begin() {
        self.result = "\n"
    }
    
    public func add(line: String) {
        self.result += self.currentIdentation + line + "\n"
    }

    public func blankLine() {
        self.result += "\n"
    }

    public func add(rawString: String) {
        self.result += rawString
    }
}
