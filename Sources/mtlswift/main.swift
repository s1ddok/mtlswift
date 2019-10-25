import Foundation
import SwiftCLI

let mtlSwift = CLI(name: "mtlswift")
mtlSwift.parser.parseOptionsAfterCollectedParameter = true
let encoderGenerator = EncoderGenerator()
mtlSwift.commands = [WatchCommand(encoderGenerator: encoderGenerator),
                     GenerateCommand(encoderGenerator: encoderGenerator)]

_ = mtlSwift.go()
