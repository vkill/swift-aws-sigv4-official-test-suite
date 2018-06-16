import AwsSigv4OfficialTestSuite
import Stencil
import class Foundation.FileManager
import class Foundation.FileHandle

func currentDirectoryPath() -> String {
    let fileBasedDir: String?

    #if Xcode
    let file = #file

    if file.contains(".build") {
        // most dependencies are in `./.build/`
        fileBasedDir = file.components(separatedBy: "/.build").first
    } else if file.contains("Packages") {
        // when editing a dependency, it is in `./Packages/`
        fileBasedDir = file.components(separatedBy: "/Packages").first
    } else {
        // when dealing with current repository, file is in `./Sources/`
        fileBasedDir = file.components(separatedBy: "/Sources").first
    }
    #else
    fileBasedDir = nil
    #endif

    let dir = fileBasedDir ?? FileManager.default.currentDirectoryPath
    return dir.hasSuffix("/") ? dir : dir + "/"
}

let workDir = currentDirectoryPath()
let generator = AwsSigv4OfficialTestSuiteGenerator(path: workDir + "official_test_suite/")

let suite = try generator.perform()
let context = [
    "suite": suite
]

let environment = Environment(loader: FileSystemLoader(paths: [.init(workDir + "templates/")]))
let swiftContent = try environment.renderTemplate(name: "swift/AwsSigv4OfficialTestSuiteContent.swift.stencil", context: context)

let fileHandle = FileHandle(forWritingAtPath: workDir + "Tests/AwsSigv4OfficialTestSuiteTests/AwsSigv4OfficialTestSuiteContent.swift")!
defer {
    fileHandle.closeFile()
}
fileHandle.write(swiftContent.data(using: .utf8)!)
