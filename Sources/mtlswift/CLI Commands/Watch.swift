import Foundation
import ArgumentParser

extension MTLSwift {

    struct Watch: ParsableCommand {

        @OptionGroup()
        var options: Options

        func validate() throws {
            if let outputPath = self.options.outputPath,
                !outputPath.contains(".swift") {
                throw ValidationError(".")
            }
        }

        func run() throws {
            let shadersFilesURLs = try MTLSwift.findShadersFiles(at: self.options.inputPaths,
                                                                 isRecursive: self.options.isRecursive)
            let ignoreURLs = try MTLSwift.findShadersFiles(at: self.options.ignoreInputPaths,
                                                           isRecursive: self.options.isRecursive)

            let shadersFilesFilteredURLs = Array(shadersFilesURLs.subtracting(ignoreURLs))
            for shadersFileURL in shadersFilesFilteredURLs {
                let observer = FileObserver(file: shadersFileURL)
                observer.start {
                    if let outputPath = self.options.outputPath {
                        let outputURL = URL(fileURLWithPath: outputPath)
                        try? EncoderGenerator.shared.generateEncoders(for: shadersFilesFilteredURLs,
                                                                      output: outputURL)
                    } else {
                        try? EncoderGenerator.shared.generateEncoders(for: [shadersFileURL])
                    }
                }

                print("watching shader file on url \(shadersFileURL)")
            }

            RunLoop.main.run()
        }

        static var configuration = CommandConfiguration(abstract: "Watch metal sources and autogenerate encoders")
    }
}
