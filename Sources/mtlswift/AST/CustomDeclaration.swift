public enum CustomDeclaration {
    
    public init?(rawString: String) {
        let scanner = StringScanner(string: rawString)
        
        if scanner.skip(exact: CustomDeclaration.swiftNameDeclaration) {
            guard let name = scanner.readWord() else {
                print("ERROR: Failed to parse \(CustomDeclaration.swiftNameDeclaration), skipping: \(scanner.leftString)")
                return nil
            }
            
            // TODO: Check it is valid Swift identifier
            self = .swiftName(name: name)
            return
        } else if scanner.skip(exact: CustomDeclaration.swiftParameterNameDeclaration) {
            guard
                let oldName = scanner.readWord(),
                scanner.skip(exact: ":"),
                let newName = scanner.readWord()
            else {
                print("ERROR: Failed to parse \(CustomDeclaration.swiftNameDeclaration), skipping: \(scanner.leftString)")
                return nil
            }
            
            // TODO: Check these are valid Swift identifiers
            self = .swiftParameterName(oldName: oldName, newName: newName)
            return
        } else if scanner.skip(exact: CustomDeclaration.swiftParameterTypeDeclaration) {
            guard
                let parameterName = scanner.readWord(),
                scanner.skip(exact: ":")
            else {
                print("ERROR: Failed to parse \(CustomDeclaration.swiftParameterTypeDeclaration), skipping: \(scanner.leftString)")
                return nil
            }

            var swiftTypeName = scanner.leftString
                                       .trimmingCharacters(in: .whitespacesAndNewlines)
            if #available(OSX 10.12, *),
               let checkedType = TypeSanitizer.sanitizeType(swiftTypeName) {
                swiftTypeName = checkedType
            }
            
            // TODO: Check these are valid Swift identifiers
            self = .swiftParameterType(parameter: parameterName, type: swiftTypeName)
            return
        } else if scanner.skip(exact: CustomDeclaration.ignoreDeclaration) {
            self = .ignore
            return
        } else if scanner.skip(exact: CustomDeclaration.accessLevelDeclaration) {
            guard let level = AccessLevel(rawValue: scanner.readWord() ?? "") else {
                print("ERROR: Failed to parse \(CustomDeclaration.accessLevelDeclaration), skipping: \(rawString), using `internal`")
                return nil
            }
            
            self = .accessLevel(level: level)
            return
        } else if scanner.skip(exact: CustomDeclaration.threadgroupSizeDelcaration) {
            if scanner.skip(exact: CustomDeclaration.maxThreadgroupSizeDelcaration) {
                self = .threadgroupSize(size: .max)
                return
            } else if scanner.skip(exact: CustomDeclaration.executionWidthThreadgroupSizeDelcaration) {
                self = .threadgroupSize(size: .executionWidth)
                return
            } else if scanner.skip(exact: CustomDeclaration.providedThreadgroupSizeDelcaration) {
                self = .threadgroupSize(size: .provided)
                return
            } else if let constant = scanner.readXYZ() {
                self = .threadgroupSize(size: .constant(x: constant.x, y: constant.y, z: constant.z))
                return
            } else {
                print("ERROR: Failed to parse \(CustomDeclaration.threadgroupSizeDelcaration), skipping: \(rawString)")
            }
        } else if scanner.skip(exact: CustomDeclaration.dispatchTypeDeclaration) {
            scanner.skipWhiteSpaces()
            if scanner.skip(exact: CustomDeclaration.noneDispatchDeclaration) {
                self = .dispatchType(type: .none)
                return
            } else if scanner.skip(exact: CustomDeclaration.exactDispatchDeclaration) {
                scanner.skipWhiteSpaces()
                if scanner.skip(exact: CustomDeclaration.providedDispatchParameterDeclaration) {
                    self = .dispatchType(type: .exact(parameters: .provided))
                    return
                } else if scanner.skip(exact: CustomDeclaration.overDispatchParameterDeclaration) {
                    if let argumentName = scanner.readWord() {
                        self = .dispatchType(type: .exact(parameters: .over(argument: argumentName)))
                        return
                    }
                } else if let xyz = scanner.readXYZ() {
                    self = .dispatchType(type: .exact(parameters: .constant(x: xyz.x, y: xyz.y, z: xyz.z)))
                    return
                }
            } else if scanner.skip(exact: CustomDeclaration.evenDispatchDeclaration) {
                scanner.skipWhiteSpaces()
                if scanner.skip(exact: CustomDeclaration.providedDispatchParameterDeclaration) {
                    self = .dispatchType(type: .even(parameters: .provided))
                    return
                } else if scanner.skip(exact: CustomDeclaration.overDispatchParameterDeclaration) {
                    if let argumentName = scanner.readWord() {
                        self = .dispatchType(type: .even(parameters: .over(argument: argumentName)))
                        return
                    }
                } else if let xyz = scanner.readXYZ() {
                    self = .dispatchType(type: .even(parameters: .constant(x: xyz.x, y: xyz.y, z: xyz.z)))
                    return
                }
            } else if scanner.skip(exact: CustomDeclaration.optimalDispatchDeclaration) {
                guard let functionConstantIndex = scanner.readBracketedInt(),
                      scanner.skip(exact: ":")
                else {
                    assertionFailure("You can't have optimal dispatch without specifying branching constant")
                    return nil
                }

                scanner.skipWhiteSpaces()
                if scanner.skip(exact: CustomDeclaration.providedDispatchParameterDeclaration) {
                    self = .dispatchType(type: .optimal(branchConstantIndex: functionConstantIndex, parameters: .provided))
                    return
                } else if scanner.skip(exact: CustomDeclaration.overDispatchParameterDeclaration) {
                    if let argumentName = scanner.readWord() {
                        self = .dispatchType(type: .optimal(branchConstantIndex: functionConstantIndex, parameters: .over(argument: argumentName)))
                        return
                    }
                } else if let xyz = scanner.readXYZ() {
                    self = .dispatchType(type: .optimal(branchConstantIndex: functionConstantIndex, parameters: .constant(x: xyz.x, y: xyz.y, z: xyz.z)))
                    return
                }
            }
        } else if scanner.skip(exact: CustomDeclaration.threadgroupMemoryDeclaration) {
            guard let index = scanner.readBracketedInt(), scanner.skip(exact: ":") else {
                assertionFailure("No index in threadgroup memory statement")
                return nil
            }

            if scanner.skip(exact: CustomDeclaration.threadgroupMemoryTotal) {
                guard let total = scanner.readInt() else {
                    assertionFailure("Illegal expression in total threadgroup memory statement")
                    return nil
                }

                self = .threadgroupMemory(index: index, length: .total(bytes: total))
                return
            } else if scanner.skip(exact: CustomDeclaration.threadgroupMemoryPerThread) {
                guard let perThread = scanner.readInt() else {
                    assertionFailure("Illegal expression in per thread threadgroup memory statement")
                    return nil
                }

                self = .threadgroupMemory(index: index, length: .thread(bytes: perThread))
                return
            } else if scanner.skip(exact: CustomDeclaration.threadgroupMemoryProvided) {
                if scanner.skip(exact: CustomDeclaration.threadgroupMemoryProvidedThread) {
                    self = .threadgroupMemory(index: index, length: .providedPerThread)
                    return
                } else if scanner.skip(exact: CustomDeclaration.threadgroupMemoryProvidedTotal) {
                    self = .threadgroupMemory(index: index, length: .providedTotal)
                    return
                }
            }
        }

        print("Illegal string passed: \(rawString)")
        return nil
    }

    public static let threadgroupMemoryDeclaration = "threadgroupMemory"
    public static let threadgroupMemoryTotal = "total:"
    public static let threadgroupMemoryPerThread = "thread:"
    public static let threadgroupMemoryProvided = "provided:"
    public static let threadgroupMemoryProvidedTotal = "total"
    public static let threadgroupMemoryProvidedThread = "total"

    case threadgroupMemory(index: Int, length: ThreadgroupMemoryLength)

    public static let threadgroupSizeDelcaration = "threadgroupSize:"
    public static let maxThreadgroupSizeDelcaration = "max"
    public static let providedThreadgroupSizeDelcaration = "provided"
    public static let executionWidthThreadgroupSizeDelcaration = "executionWidth"

    case threadgroupSize(size: ThreadgroupSize)
    
    public static let dispatchTypeDeclaration = "dispatch:"
    public static let noneDispatchDeclaration = "none"
    public static let evenDispatchDeclaration = "even:"
    public static let exactDispatchDeclaration = "exact:"
    public static let optimalDispatchDeclaration = "optimal"
    public static let overDispatchParameterDeclaration = "over:"
    public static let providedDispatchParameterDeclaration = "provided"
    case dispatchType(type: DispatchType)
    
    public static let accessLevelDeclaration = "accessLevel:"
    case accessLevel(level: AccessLevel)
    
    public static let swiftNameDeclaration = "swiftName:"
    case swiftName(name: String)
    
    public static let swiftParameterNameDeclaration = "swiftParameterName:"
    case swiftParameterName(oldName: String, newName: String)
    
    public static let swiftParameterTypeDeclaration = "swiftParameterType:"
    case swiftParameterType(parameter: String, type: String)
    
    public static let ignoreDeclaration = "ignore"
    case ignore
    
    public static let declarationPrefix = "mtlswift:"
    
    public func sameCategory(with other: CustomDeclaration) -> Bool {
        switch (self, other) {
            case (.ignore, .ignore),
                 (.swiftParameterType(_, _), .swiftParameterType(_, _)),
                 (.swiftParameterName(_, _), .swiftParameterName(_, _)),
                 (.swiftName(_), .swiftName(_)),
                 (.accessLevel(_), .accessLevel(_)),
                 (.dispatchType(_), .dispatchType(_)),
                 (.threadgroupSize(_), .threadgroupSize(_)),
                 (.threadgroupMemory(_, _), .threadgroupMemory(_, _))
            : return true
        default:
            return false
        }
    }
}

public extension Array where Element == CustomDeclaration {
    func first(of category: CustomDeclaration) -> CustomDeclaration? {
        return self.first {
            if $0.sameCategory(with: category) {
                return true
            } else {
                return false
            }
        }
    }
}
