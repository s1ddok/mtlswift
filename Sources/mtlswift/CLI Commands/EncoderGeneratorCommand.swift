//
//  EncoderGeneratorCommand.swift
//  mtlswift
//
//  Created by Eugene Bokhan on 25.10.2019.
//

import Foundation
import SwiftCLI
import Files

class EncoderGeneratorCommand {

    // MARK: - Properties

    // Generator
    let encoderGenerator: EncoderGenerator
    // Command
    let inputPaths = CollectedParameter()
    let encodersPath = Key<String>("-o", "--output",
                                   description: "generated encoders path",
                                   validation: [.contains(".swift")])
    let ignorePaths = VariadicKey<String>("-i", "--ignore",
                                          description: "ignored shader file path",
                                          validation: [.contains(".metal")])
    let recursiveFlag = Flag("-r", "--recursive",
                             description: "recursive search in folders",
                             defaultValue: false)
    var shadersFilesURLs: Set<URL> = []

    // MARK: - LifeCycle

    init(encoderGenerator: EncoderGenerator) {
        self.encoderGenerator = encoderGenerator
    }

    // MARK: - Setup

    func setup() throws {
        let shadersFilesURLs = try self.findShadersFiles(at: self.inputPaths.value)
        let ignoreURLs = try self.findShadersFiles(at: self.ignorePaths.value)

        self.shadersFilesURLs = shadersFilesURLs.subtracting(ignoreURLs)
    }

    private func findShadersFiles(at paths: [String]) throws -> Set<URL> {
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
            if recursiveFlag.value {
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
