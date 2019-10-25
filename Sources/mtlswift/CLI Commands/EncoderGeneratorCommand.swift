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
        let inputPaths = Set<String>(self.inputPaths.value)
        var shadersFilesPaths: Set<String> = []
        var foldersPaths: Set<String> = []

        // 1. Sort .metal URLs and folders URLs.
        inputPaths.forEach {
            if let folder = try? Folder(path: $0) {
                foldersPaths.insert(folder.path)
            } else if ($0 as NSString).pathExtension == "metal" {
                shadersFilesPaths.insert($0)
            }
        }

        // 2. Search for .metal files in the folders
        let folders = try foldersPaths.map { try Folder(path: $0) }
        try folders.forEach { folder in
            folder.files.filter { ($0.path as NSString).pathExtension == "metal"}
                        .forEach { shadersFilesPaths.insert($0.path) }
            if recursiveFlag.value {
                let subfoldersPaths = Set(folder.subfolders
                                                .recursive
                                                .map { $0.path })
                let subfolders = try subfoldersPaths.map { try Folder(path: $0) }
                subfolders.forEach { folder in
                    folder.files.filter { ($0.path as NSString).pathExtension == "metal"}
                                           .forEach { shadersFilesPaths.insert($0.path) }
                }
            }
        }

        // 3. Take in account ignore paths.
        let ignorePaths = Set<String>(self.ignorePaths.value)
        self.shadersFilesURLs = Set(shadersFilesPaths.subtracting(ignorePaths)
                                                     .map { URL(fileURLWithPath: $0) })
    }
}

