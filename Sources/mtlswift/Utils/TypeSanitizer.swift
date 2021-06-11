import Foundation

@available(OSX 10.12, *)
struct TypeSanitizer {

    private init() {}

    static func sanitizeType(_ type: String) -> String? {
        let url = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask)[0].appendingPathComponent("\(UUID().uuidString).swift",
                                                                                          isDirectory: false)
        defer { try? FileManager.default.removeItem(at: url) }

        let swiftString = """
        import Foundation
        import simd
        import Metal
        import MetalPerformanceShaders
        print(String(describing: type(of: \(type).self)).replacingOccurrences(of: ".Type", with: ""))
        """

        let swiftStringData = Data(swiftString.utf8)

        do { try swiftStringData.write(to: url) }
        catch { return nil }

        let process = Process()
        let outputPipe = Pipe()
        process.launchPath = which("swift")!

        process.arguments = ["\(url.path)"]
        process.standardOutput = outputPipe
        process.launch()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading
                                   .readDataToEndOfFile()

        let output = String(decoding: outputData,
                            as: UTF8.self).replacingOccurrences(of: "\n", with: "")

        return output == "" ? nil : output
    }
}
