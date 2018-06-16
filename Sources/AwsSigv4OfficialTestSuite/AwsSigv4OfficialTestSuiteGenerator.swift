import class Foundation.FileManager
import class Foundation.FileHandle
import struct Foundation.Data
import struct Foundation.URL

public final class AwsSigv4OfficialTestSuiteGenerator {
    private enum CaseFileSuffix: String {
        case req = "req"
        case creq = "creq"
        case sts = "sts"
        case authz = "authz"
        case sreq = "sreq"

        static func allCases() -> [CaseFileSuffix] {
            return [
                .req,
                .creq,
                .sts,
                .authz,
                .sreq,
            ]
        }
    }

    let path: String

    public init(path: String){
        self.path = path
    }

    public func perform() throws -> AwsSigv4OfficialTestSuite {
        let credentialScope = try fileContent(self.path + "credential_scope")
        let secretKey = try fileContent(self.path + "secret_key")
        var cases: [AwsSigv4OfficialTestSuite.Case] = []

        for (caseName, caseValue) in try getTestSuite() {
            cases.append(
                AwsSigv4OfficialTestSuite.Case(
                    name: caseName,
                    req: caseValue[.req]!,
                    creq: caseValue[.creq]!,
                    sts: caseValue[.sts]!,
                    authz: caseValue[.authz]!,
                    sreq: caseValue[.sreq]!
                )
            )
        }

        return AwsSigv4OfficialTestSuite(credentialScope: credentialScope, secretKey: secretKey, cases: cases)
    }

    private func getTestSuite() throws -> [String:[CaseFileSuffix:String]] {
        var suite: [String:[CaseFileSuffix:String]] = [:]

        let fileManager = FileManager.default

        let paths = try fileManager.subpathsOfDirectory(atPath: self.path + "aws-sig-v4-test-suite/").filter { $0.hasSuffix(".req") }
        for path in paths {
            let pathURL = URL(fileURLWithPath: self.path + "aws-sig-v4-test-suite/" + path)

            let caseName = pathURL.deletingPathExtension().lastPathComponent
            var caseValue: [CaseFileSuffix:String] = [:]

            let parentPathURL = pathURL.deletingLastPathComponent()
            let fileURLs = try fileManager.contentsOfDirectory(at: parentPathURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                let extname = fileURL.pathExtension
                guard let caseFileSuffix = CaseFileSuffix(rawValue: extname) else {
                    fatalError()
                }
                caseValue[caseFileSuffix] = try fileContent(fileURL.path)
            }

            suite[caseName] = caseValue
        }

        return suite
    }

    private func fileContent(_ filePath: String) throws -> String {
        let fileHandle = FileHandle(forReadingAtPath: filePath)!
        defer {
            fileHandle.closeFile()
        }
        let data = fileHandle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
    }
}
