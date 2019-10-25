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

    let shadersPaths = CollectedParameter(validation: [.contains(".metal")])
    let encodersPath = Key<String>("-o", "--output",
                                   description: "generated encoders path",
                                   validation: [.contains(".swift")])
    let ignorePaths = VariadicKey<String>("-i", "--ignore",
                                          description: "ignored shader file path",
                                          validation: [.contains(".metal")])

    // MARK: - LifeCycle

    init(encoderGenerator: EncoderGenerator) {
        self.encoderGenerator = encoderGenerator
    }

    // MARK: - Execute

    func execute() throws {
        let ignorePaths = Set<String>(self.ignorePaths.value)
        let shadersPaths = Set<String>(self.shadersPaths.value)
        let shadersURLs = shadersPaths.subtracting(ignorePaths)
                                      .map { URL(fileURLWithPath: $0) }

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
