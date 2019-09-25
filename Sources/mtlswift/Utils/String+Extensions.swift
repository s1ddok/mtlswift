//
//  String+Extensions.swift
//  mtlswift
//
//  Created by Andrey Volodin on 25/09/2019.
//

import Foundation

extension String: Error {
    /// Replaces all occurrences of characters in the provided set with
    /// the provided string.
    func replacing(charactersIn characterSet: CharacterSet,
                   with separator: String) -> String {
        let components = self.components(separatedBy: characterSet)
        return components.joined(separator: separator)
    }
}

public extension String {
    var extractingLevel: (Int, String) {
        var level = 0
        var trimmedSelf = self
        while true {
            if ["|-", "`-", "| ", "  "].contains(where: { trimmedSelf.hasPrefix($0) }) {
                trimmedSelf.removeFirst(2)
                level += 1
                continue
            }

            break
        }

        return (level, trimmedSelf)
    }
}
