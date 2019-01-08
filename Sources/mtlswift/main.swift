import Clang
import cclang
import Foundation

public extension String {
    var extractingLevel: (Int, String) {
        var level = 0
        var trimmedSelf = self
        while true {
            if ["|-", "`-", "| ", "  "].contains(where: { trimmedSelf.hasPrefix($0) }) {
                trimmedSelf.removeFirst(2)
                level += 1
                continue
            }
            
            break
        }
        
        return (level, trimmedSelf)
    }
}

do {
    let lines = try String(contentsOfFile: CommandLine.arguments[1]).components(separatedBy: .newlines)
    
    let firstLine = lines.first!.extractingLevel
    var currentLevel = firstLine.0
    
    let topNode = try ASTNode(parsingString: firstLine.1)
    var node = topNode
    for line in lines.dropFirst().dropLast() {
        let extractingLevel = line.extractingLevel
        
        while currentLevel >= extractingLevel.0 {
            node = node.parent!
            currentLevel -= 1
        }
        
        guard extractingLevel.1 != "<<<NULL>>>" else {
            continue
        }
        
        let newChild = try ASTNode(parsingString: extractingLevel.1)
        newChild.parent = node
        node.children.append(newChild)
        node = newChild
        currentLevel = extractingLevel.0
    }
    
    let shaders = topNode.extractMetalShaders()
    shaders.forEach { print($0.description) }
    
    /*let unit =
        try TranslationUnit(clangSource: String(contentsOfFile: "/Users/avolodin/Documents/Shaders.metal"),
                            language: .cPlusPlus,
                            index: Index(excludeDeclarationsFromPCH: false,
                                         displayDiagnostics: false),
                            commandLineArgs: [],
                            options: [.skipFunctionBodies, .keepGoing])

    var tokens = unit.tokens(in: unit.cursor.range)
    
    var balancedScopeScores = 0
    
    enum ScopeIndexingState {
        case none, potentiallyScopeStart, insideScope
    }
    
    var state: ScopeIndexingState = .none
    
    var i = 0
    while i < tokens.count {
        let currentToken = tokens[i]
        
        if currentToken is CommentToken {
            if case .insideScope = state {
                tokens.remove(at: i)
                continue;
            } else {
                i += 1
                continue;
            }
        }
        
        if currentToken is PunctuationToken {
            switch state {
            case .none:
                if currentToken.spelling(in: unit) == ")" {
                    state = .potentiallyScopeStart
                }
            case .potentiallyScopeStart:
                if currentToken.spelling(in: unit) == "{" {
                    state = .insideScope
                    balancedScopeScores = 1
                } else {
                    state = .none
                }
            case .insideScope:
                if currentToken.spelling(in: unit) == "{" {
                    balancedScopeScores += 1
                } else if currentToken.spelling(in: unit) == "}" {
                    balancedScopeScores -= 1
                    if balancedScopeScores == 0 {
                        state = .none
                    }
                }

                tokens.remove(at: i)
                continue
            }
        }
        
        if currentToken is KeywordToken || currentToken is IdentifierToken || currentToken is LiteralToken {
            if case .insideScope = state {
                tokens.remove(at: i)
                continue;
            } else {
                i += 1
                continue;
            }
        }
        
        i += 1
    }
    
    print(tokens.map { $0.spelling(in: unit)})*/
} catch {
    print(error.localizedDescription)
}
