import Foundation
import ArgumentParser

extension MTLSwift {

    struct Generate: ParsableCommand {

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
            if let outputPath = self.options.outputPath {
                let outputURL = URL(fileURLWithPath: outputPath)
                shadersFilesFilteredURLs.forEach {
                    print("generating encoder for shader file on url \($0)")
                }
                try EncoderGenerator.shared.generateEncoders(for: shadersFilesFilteredURLs,
                                                             output: outputURL)
            } else {
                try shadersFilesFilteredURLs.forEach {
                    print("generating encoder for shader file on url \($0)")
                    try EncoderGenerator.shared.generateEncoders(for: [$0])
                }
            }
        }

        static var configuration = CommandConfiguration(abstract: "Generate encoders from metal sources.")
    }

}
