import Clang
import cclang
import Foundation

do {
    let start = Date()
    let path = CommandLine.arguments[1]

    guard let url = URL(string: path) else {
        throw "Passed string is not a valid URL"
    }

    let shaderGenerator = ShaderGenerator()

    if url.pathExtension == "metal" {
        try shaderGenerator.generateShaders(for: URL(fileURLWithPath: url.absoluteString))
    } else {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else {
            throw "Couldn't access niether file nor directory at \(path)"
        }

        while let metalFile = enumerator.nextObject() as? NSString {
            if metalFile.hasSuffix("metal") {
                let metalFileURL = URL(fileURLWithPath: url.path + "/" + (metalFile as String))
                try shaderGenerator.generateShaders(for: metalFileURL)
            }
        }
    }

    print("Finished in \(Date().timeIntervalSince(start))")

    RunLoop.main.run()
} catch {
    print(error.localizedDescription)
}
