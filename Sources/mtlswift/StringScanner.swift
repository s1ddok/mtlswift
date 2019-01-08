//
//  StringScanner.swift
//  mtlswift
//
//  Created by Andrey Volodin on 08/01/2019.
//

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
        try! self.skipIfAny(pattern: "^*0[xX][0-9a-fA-F]+")
    }
    
    public func skipSlocIfAny() {
        try! self.skipIfAny(pattern: "((<<invalid sloc>>|<invalid sloc>|<(\"?/?.*?)(:\\d+)+(,\\s((\"?/?.*?)(:\\d+)+))*>)\\s*)+((line|col)(:\\d+)+)?")
    }
    
    public func skipUsedStatement() {
        try! self.skipIfAny(pattern: "used(\\sa)?")
    }
    
    public func readWordIfAny() -> String? {
        let regex = try! NSRegularExpression(pattern: "^(\\w+)", options: [])
        
        if let match = regex.firstMatch(in: self.string,
                                        options: [],
                                        range: self.leftRange) {
            self.offset += match.range.length
            
            return self.stringFromLeftString(in: match.range(at: 1))
        }
        
        return nil
    }
    
    public func readSingleQuotedTextIfAny() -> String? {
        let regex = try! NSRegularExpression(pattern: "^'(.*?)'", options: [])
        
        if let match = regex.firstMatch(in: self.string,
                                        options: [],
                                        range: self.leftRange) {
            self.offset += match.range.length
            
            return self.stringFromLeftString(in: match.range(at: 1))
        }
        
        return nil
    }
    
    public var leftString: String {
        return String(self.string[self.string.index(self.string.startIndex, offsetBy: self.offset)...])
    }
    
}
