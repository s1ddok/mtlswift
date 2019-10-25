//
//  WatchCommand.swift
//  
//
//  Created by Eugene Bokhan on 24.10.2019.
//

import Foundation
import SwiftCLI
import Files

final class WatchCommand: EncoderGeneratorCommand, Command {

    // MARK: - Properties

    // Command
    let name = "watch"
    let shortDescription = "watch metal sources and autogenerate encoders"

    // MARK: - Execute

    func execute() throws {
        try self.setup()

        let shadersURLs = Array(self.shadersFilesURLs)
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
