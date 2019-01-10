//
//  CustomDeclaration.swift
//  mtlswift
//
//  Created by Andrey Volodin on 10/01/2019.
//

public enum CustomDeclaration {
    public enum AccessLevel: String {
        case `public` = "public"
        case `private` = "private"
        case `fileprivate` = "fileprivate"
        case `internal` = "internal"
        case `open` = "open"
    }
    
    public init?(rawString: String) {
        let scanner = StringScanner(string: rawString)
        
        if scanner.skip(exact: CustomDeclaration.swiftNameDeclaration) {
            guard let name = scanner.readWordIfAny() else {
                print("ERROR: Failed to parse \(CustomDeclaration.swiftNameDeclaration), skipping: \(scanner.leftString)")
                return nil
            }
            
            // TODO: Check it is valid Swift identifier
            self = .swiftName(name: name)
            return
        } else if scanner.skip(exact: CustomDeclaration.swiftParameterNameDeclaration) {
            guard
                let oldName = scanner.readWordIfAny(),
                scanner.skip(exact: ":"),
                let newName = scanner.readWordIfAny()
            else {
                print("ERROR: Failed to parse \(CustomDeclaration.swiftNameDeclaration), skipping: \(scanner.leftString)")
                return nil
            }
            
            // TODO: Check these are valid Swift identifiers
            self = .swiftParameterName(oldName: oldName, newName: newName)
            return
        } else if scanner.skip(exact: CustomDeclaration.swiftParameterTypeDeclaration) {
            guard
                  let parameterName = scanner.readWordIfAny(),
                  scanner.skip(exact: ":"),
                  let swiftTypeName = scanner.readWordIfAny()
                else {
                    print("ERROR: Failed to parse \(CustomDeclaration.swiftParameterTypeDeclaration), skipping: \(scanner.leftString)")
                    return nil
            }
            
            // TODO: Check these are valid Swift identifiers
            self = .swiftParameterType(parameter: parameterName, type: swiftTypeName)
            return
        } else if scanner.skip(exact: CustomDeclaration.ignoreDeclaration) {
            self = .ignore
            return
        } else if scanner.skip(exact: CustomDeclaration.accessLevelDeclaration) {
            guard let level = AccessLevel(rawValue: scanner.readWordIfAny() ?? "") else {
                print("ERROR: Failed to parse \(CustomDeclaration.accessLevelDeclaration), skipping: \(scanner.leftString), using `internal`")
                return nil
            }
            
            self = .accessLevel(level: level)
            return
        }
        
        return nil
    }
    
    public static let accessLevelDeclaration = "accessLevel:"
    case accessLevel(level: AccessLevel)
    
    public static let swiftNameDeclaration = "swiftName:"
    case swiftName(name: String)
    
    public static let swiftParameterNameDeclaration = "swiftParameterName:"
    case swiftParameterName(oldName: String, newName: String)
    
    public static let swiftParameterTypeDeclaration = "swiftParamteterType:"
    case swiftParameterType(parameter: String, type: String)
    
    public static let ignoreDeclaration = "ignore"
    case ignore
    
    public static let declarationPrefix = "mtlswift:"
}
