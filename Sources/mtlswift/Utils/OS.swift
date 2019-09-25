//
//  OS.swift
//  mtlswift
//
//  Created by Andrey Volodin on 25/09/2019.
//

import Foundation

/// Runs the specified program at the provided path.
/// - parameter path: The full path of the executable you
///                   wish to run.
/// - parameter args: The arguments you wish to pass to the
///                   process.
/// - returns: The standard output of the process, or nil if it was empty.
func run(_ path: String, args: [String] = []) -> String? {
    let pipe = Pipe()
    let process = Process()
    process.launchPath = path
    process.arguments = args
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let result = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !result.isEmpty else { return nil }
    return result
}

/// Finds the location of the provided binary on your system.
func which(_ name: String) -> String? {
    return run("/usr/bin/which", args: [name])
}
