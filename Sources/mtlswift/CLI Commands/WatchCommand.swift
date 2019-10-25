//
//  WatchCommand.swift
//  
//
//  Created by Eugene Bokhan on 24.10.2019.
//

import Foundation
import SwiftCLI

class WatchCommand: Command {

    // MARK: - Properties

    // Generator
    let encoderGenerator: EncoderGenerator
    // Command
    let name = "watch"
    let shortDescription = "watch metal sources and autogenerate encoders"
    let encodersPath = Key<String>("-o", "--output",
                                   description: "generated encoders path",
                                   validation: [.contains(".swift")])
    let shadersPaths = CollectedParameter(validation: [.contains(".metal")])

    // MARK: - LifeCycle

    init(encoderGenerator: EncoderGenerator) {
        self.encoderGenerator = encoderGenerator
    }

    // MARK: - Execute

    func execute() throws {
        let shadersURLs = self.shadersPaths.value.map { URL(fileURLWithPath: $0) }
        for shadersURL in shadersURLs {

            let observer = FileObserver(file: shadersURL)
            observer.start {
                if let outputPath = self.encodersPath.value {
                    let outputURL = URL(fileURLWithPath: outputPath)
                    try? self.encoderGenerator.generateEncoders(for: shadersURLs,
                                                                output: outputURL)
                } else {
                    try? self.encoderGenerator.generateEncoders(for: [shadersURL])
                }
            }

            stdout <<< "watching shader file on url \(shadersURL)"
        }

        RunLoop.main.run()
    }
}
