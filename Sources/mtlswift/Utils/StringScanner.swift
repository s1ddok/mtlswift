import Foundation

public class StringScanner {
    public let string: String
    
    fileprivate var offset: Int = 0
    fileprivate var leftRange: NSRange {
        return NSRange(self.string.index(self.string.startIndex, offsetBy: self.offset)...,
                       in: self.string)
    }
    
    fileprivate func stringFromLeftString(in range: NSRange) -> String {
        return String(self.string[self.string.index(self.string.startIndex, offsetBy: range.lowerBound)..<self.string.index(self.string.startIndex, offsetBy: range.upperBound)])
    }
    
    public init(string: String) {
        self.string = string
    }
    
    public func skipIfAny(pattern: String) throws {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        
        if let match = regex.firstMatch(in: self.string,
                                        options: [],
                                        range: self.leftRange) {
            self.offset += match.range.length
        }
    }
    
    public func skipWhiteSpaces() {
        try! self.skipIfAny(pattern: "^\\s*")
    }
    
    public func skipHexIfAny() {
        try! self.skipIfAny(pattern: "0[xX][0-9a-fA-F]+")
    }

    public func skipSlocIfAny() {
        try! self.skipIfAny(pattern: "((<<invalid sloc>>|" +
            "<invalid sloc>|" +
            "<(\"?/?.*?)(:\\d+)+(,\\s((\"?/?.*?)(:\\d+)+))*>)\\s*)+" +
            "((line|col)(:\\d+)+)?")
    }
    
    public func skipUsedStatement() {
        try! self.skipIfAny(pattern: "used(\\sa\\s)?")
    }

    public func skipInvalidStatement() {
        try! self.skipIfAny(pattern: "invalid(\\sa\\s)?")
    }
    
    public func read(pattern: String) throws -> String? {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        
        if let match = regex.firstMatch(in: self.string,
                                        options: [],
                                        range: self.leftRange) {
            self.offset += match.range.length
            
            return self.stringFromLeftString(in: match.range(at: 1))
        }
        
        return nil
    }

    public func readAll(pattern: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])

        let matches = regex.matches(in: self.string, options: [], range: self.leftRange)

        return matches.map { self.stringFromLeftString(in: $0.range(at: 0)) }
    }
    
    public func readWord() -> String? {
        return try! self.read(pattern: "^(\\w+)")
    }
    
    public func readInt() -> Int? {
        return Int(try! self.read(pattern:  "^(\\d+)") ?? "")
    }
    
    public func readSingleQuotedTextIfAny() -> String? {
        return try! self.read(pattern: "^'(.*?)'")
    }

    public func readBracketedInt() -> Int? {
        return try! Int(self.read(pattern: "^\\((\\d+)\\)") ?? "")
    }
    
    public func readTextAttribute() -> String? {
        return try! self.read(pattern: "^Text=\"(.*)\"")
    }
    
    public func readXYZ() -> (x: Int, y: Int, z: Int)? {
        let x = self.readInt()
        self.skipWhiteSpaces()
        guard self.skip(exact: ",") else {
            return nil
        }
        self.skipWhiteSpaces()
        let y = self.readInt()
        self.skipWhiteSpaces()
        guard self.skip(exact: ",") else {
            return nil
        }
        self.skipWhiteSpaces()
        
        let z = self.readInt()
        
        if x != nil && y != nil && z != nil {
            return (x!, y!, z!)
        }
        
        return nil
    }
    
    public func skip(exact: String) -> Bool {
        if self.string.dropFirst(self.offset).hasPrefix(exact) {
            self.offset += exact.count
            return true
        }
        
        return false
    }
    
    public var leftString: String {
        return String(self.string[self.string.index(self.string.startIndex, offsetBy: self.offset)...])
    }
    
}
