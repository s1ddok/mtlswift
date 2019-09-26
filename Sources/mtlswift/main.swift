import Foundation

do {
    let firstArgument = CommandLine.arguments[1]
    let secondArgument = CommandLine.arguments[2]
    let shaderGenerator = ShaderGenerator()

    var observers: [FileObserver] = []

    if firstArgument == "watch" {
        guard let url = URL(string: secondArgument) else {
            throw ""
        }
        if url.pathExtension == "metal" {
            let fileURL = URL(fileURLWithPath: url.absoluteString)

            let observer = FileObserver(file: fileURL)
            observer.start {
                try? shaderGenerator.generateShaders(for: fileURL)
            }
            observers.append(observer)
        } else {
            guard let enumerator = FileManager.default.enumerator(atPath: secondArgument) else {
                throw "Couldn't access neither file nor directory at \(firstArgument)"
            }

            while let metalFile = enumerator.nextObject() as? NSString {
                if metalFile.hasSuffix("metal") {
                    let metalFileURL = URL(fileURLWithPath: url.path + "/" + (metalFile as String))
                    let observer = FileObserver(file: metalFileURL)
                    observer.start {
                        try? shaderGenerator.generateShaders(for: metalFileURL)
                    }
                    observers.append(observer)
                }
            }
        }

        RunLoop.main.run()
    } else if let url = URL(string: firstArgument) {
        if url.pathExtension == "metal" {
            let fileURL = URL(fileURLWithPath: url.absoluteString)
            try shaderGenerator.generateShaders(for: fileURL)
        } else {
            guard let enumerator = FileManager.default.enumerator(atPath: firstArgument) else {
                throw "Couldn't access neither file nor directory at \(firstArgument)"
            }

            while let metalFile = enumerator.nextObject() as? NSString {
                if metalFile.hasSuffix("metal") {
                    let metalFileURL = URL(fileURLWithPath: url.path + "/" + (metalFile as String))
                    try shaderGenerator.generateShaders(for: metalFileURL)
                }
            }
        }
    } else {
        throw "Passed string is not a valid URL"
    }
} catch {
    print(error.localizedDescription)
}
