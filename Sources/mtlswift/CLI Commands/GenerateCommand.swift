//
//  GenerateCommand.swift
//  SwiftCLI
//
//  Created by Eugene Bokhan on 25.10.2019.
//

import Foundation
import SwiftCLI

class GenerateCommand: Command {

    // MARK: - Properties

    // Generator
    let encoderGenerator: EncoderGenerator
    // Command
    let name = "generate"
    let shortDescription = "generate encoders from metal sources"

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

            if let outputPath = self.encodersPath.value {
                let outputURL = URL(fileURLWithPath: outputPath)
                try? self.encoderGenerator.generateEncoders(for: shadersURLs,
                                                            output: outputURL)
            } else {
                try? self.encoderGenerator.generateEncoders(for: [shadersURL])
            }

            stdout <<< "generating encoder for shader file on url \(shadersURL)"
        }

    }
}
