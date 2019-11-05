//
//  GenerateCommand.swift
//  SwiftCLI
//
//  Created by Eugene Bokhan on 25.10.2019.
//

import Foundation
import SwiftCLI
import Files

final class GenerateCommand: EncoderGeneratorCommand, Command {

    // MARK: - Properties

    // Command
    let name = "generate"
    let shortDescription = "generate encoders from metal sources"

    // MARK: - Execute

    func execute() throws {
        try self.setup()

        let shadersURLs = Array(self.shadersFilesURLs)
        if let outputPath = self.encodersPath.value {
            let outputURL = URL(fileURLWithPath: outputPath)
            shadersURLs.forEach {
                stdout <<< "generating encoder for shader file on url \($0)"
            }
            try self.encoderGenerator.generateEncoders(for: shadersURLs,
                                                       output: outputURL)
        } else {
            try shadersURLs.forEach {
                stdout <<< "generating encoder for shader file on url \($0)"
                try self.encoderGenerator.generateEncoders(for: [$0])
            }
        }

    }
}
