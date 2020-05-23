import Foundation
import ArgumentParser
import Files

struct MTLSwift: ParsableCommand {

    struct Options: ParsableArguments {
        @Argument(help: "Input Paths.")
        var inputPaths: [String]

        @Option(name: .shortAndLong,
                help: "Ignored shaders file path.")
        var ignoreInputPaths: [String]

        @Option(name: .shortAndLong,
                help: "Generated encoders path.")
        var outputPath: String?

        @Flag(name: [.customLong("recursive"), .customShort("r")],
              help: "Recursive search in folders.")
        var isRecursive: Bool
    }

    static var configuration = CommandConfiguration(
        abstract: "A utility for generating metal shaders encoders.",
        subcommands: [Generate.self, Watch.self],
        defaultSubcommand: Generate.self
    )

    static func setup(using options: Options) throws -> Set<URL> {
        let shadersFilesURLs = try Self.findShadersFiles(at: options.inputPaths,
                                                         isRecursive: options.isRecursive)
        let ignoreURLs = try Self.findShadersFiles(at: options.ignoreInputPaths,
                                                   isRecursive: options.isRecursive)

        return shadersFilesURLs.subtracting(ignoreURLs)
    }

    static func findShadersFiles(at paths: [String], isRecursive: Bool) throws -> Set<URL> {
        let inputPaths = Set<String>(paths)
        var foundShadersFilesPaths: Set<String> = []
        var foldersPaths: Set<String> = []

        // 1. Sort .metal URLs and folders URLs.
        inputPaths.forEach {
            if let folder = try? Folder(path: $0) {
                foldersPaths.insert(folder.path)
            } else if $0.pathExtension == "metal" {
                foundShadersFilesPaths.insert($0)
            }
        }

        // 2. Search for .metal files in the folders.
        let folders = try foldersPaths.map { try Folder(path: $0) }
        try folders.forEach { folder in
            folder.files.filter { $0.path.pathExtension == "metal"}
                        .forEach { foundShadersFilesPaths.insert($0.path) }
            if isRecursive {
                let subfoldersPaths = Set(folder.subfolders
                                                .recursive
                                                .map { $0.path })
                let subfolders = try subfoldersPaths.map { try Folder(path: $0) }
                subfolders.forEach { folder in
                    folder.files.filter { $0.path.pathExtension == "metal"}
                                .forEach { foundShadersFilesPaths.insert($0.path) }
                }
            }
        }

        let result = Set(foundShadersFilesPaths.map { URL(fileURLWithPath: $0) })
        return result
    }
}

fileprivate extension String {
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
}
