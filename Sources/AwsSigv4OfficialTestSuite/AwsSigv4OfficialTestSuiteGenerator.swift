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

    private enum CaseRequestState {
        case begin
        case onMethod
        case onRequestURI
        case onHTTPVersion
        case onMessageHeaders
        case onMessageBody
        case end
    }

    let path: String

    public init(path: String){
        self.path = path
    }

    public func perform() throws -> AwsSigv4OfficialTestSuite {
        let credentialScope = try readFileContent(self.path + "credential_scope")
        let secretKey = try readFileContent(self.path + "secret_key")
        var cases: [AwsSigv4OfficialTestSuite.Case] = []

        for (caseName, caseValue) in try getTestSuite() {
            cases.append(
                AwsSigv4OfficialTestSuite.Case(
                    name: caseName,
                    req: try makeCaseRequest(caseValue[.req]!),
                    creq: caseValue[.creq]!,
                    sts: caseValue[.sts]!,
                    authz: caseValue[.authz]!,
                    sreq: try makeCaseRequest(caseValue[.sreq]!)
                )
            )
        }

        return AwsSigv4OfficialTestSuite(credentialScope: credentialScope, secretKey: secretKey, cases: cases)
    }

    private func readFileContent(_ filePath: String) throws -> String {
        let fileHandle = FileHandle(forReadingAtPath: filePath)!
        defer {
            fileHandle.closeFile()
        }
        let data = fileHandle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
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
                caseValue[caseFileSuffix] = try readFileContent(fileURL.path)
            }

            suite[caseName] = caseValue
        }

        return suite
    }

    private func makeCaseRequest(_ text: String) throws -> AwsSigv4OfficialTestSuite.Case.Request {
        let encoding: String.Encoding = .utf8
        var data = text.data(using: encoding, allowLossyConversion: true)!

        var method: String = ""
        var requestURI: String = ""
        var httpVersion: String = ""
        var messageHeaders: [[String]] = []
        var messageBody: String?

        var messageHeader: Data
        var messageHeaderFieldName: String = ""
        var messageHeaderFieldValue: String = ""

        var headerTransferEncodingChunked = false
        var headerContentLength: Int? = nil

        let SP = " ".data(using: encoding)!
        let SPHTTPSLASH = " HTTP/".data(using: encoding)!
        let CRLF = "\n".data(using: encoding)! //TODO lost \r
        let COLON = ":".data(using: encoding)!

        var state = CaseRequestState.begin
        while state != .end {
            switch state {
            case .begin:
                state = .onMethod
            case .onMethod:
                guard let range = data.range(of: SP) else {
                    fatalError()
                }
                method = String(data: data.subdata(in: 0..<range.lowerBound), encoding: encoding)!
                data.removeSubrange(0..<range.upperBound)
                state = .onRequestURI
            case .onRequestURI:
                guard let range = data.range(of: SPHTTPSLASH) else {
                    fatalError()
                }
                requestURI = String(data: data.subdata(in: 0..<range.lowerBound), encoding: encoding)!
                data.removeSubrange(0..<range.upperBound)
                state = .onHTTPVersion
            case .onHTTPVersion:
                guard let range = data.range(of: CRLF) else {
                    fatalError()
                }
                httpVersion = String(data: data.subdata(in: 0..<range.lowerBound), encoding: encoding)!
                data.removeSubrange(0..<range.upperBound)
                state = .onMessageHeaders
            case .onMessageHeaders:
                if let _ = data.range(of: CRLF) {
                } else {
                    // Lose CRLFCRLF
                    data.append(CRLF)
                    data.append(CRLF)
                }
                guard let range = data.range(of: CRLF) else {
                    fatalError()
                }
                if range.lowerBound == 0 {
                    data.removeSubrange(0..<range.upperBound)
                    state = .onMessageBody

                    if !messageHeaderFieldName.isEmpty {
                        messageHeaders.append([messageHeaderFieldName, messageHeaderFieldValue])
                        messageHeaderFieldName = ""
                        messageHeaderFieldValue = ""
                    }
                    
                    continue
                }
                messageHeader = data.subdata(in: 0..<range.lowerBound)
                data.removeSubrange(0..<range.upperBound)

                guard let rangeColon = messageHeader.range(of: COLON) else {
                    if !messageHeaderFieldName.isEmpty {
                        messageHeaderFieldValue.append(String(data: messageHeader, encoding: encoding)!)
                        continue
                    }
                    fatalError()
                }

                if !messageHeaderFieldName.isEmpty {
                    messageHeaders.append([messageHeaderFieldName, messageHeaderFieldValue])
                    messageHeaderFieldName = ""
                    messageHeaderFieldValue = ""
                }

                guard rangeColon.lowerBound > 0 else {
                    fatalError()
                }
                messageHeaderFieldName = String(data: messageHeader.subdata(in: 0..<rangeColon.lowerBound), encoding: encoding)!
                if rangeColon.upperBound == messageHeader.count {
                    messageHeaderFieldValue = ""
                } else {
                    messageHeaderFieldValue = String(data: messageHeader.subdata(in: rangeColon.upperBound..<messageHeader.count), encoding: encoding)!
                }

                switch messageHeaderFieldName.lowercased() {
                case "content-length":
                    headerContentLength = Int(messageHeaderFieldValue)
                    if headerContentLength! < 0 {
                        fatalError()
                    }
                case "transfer-encoding":
                    if messageHeaderFieldValue.lowercased() == "chunked" {
                        headerTransferEncodingChunked = true
                    }
                default:
                    ()
                }

                continue
            case .onMessageBody:
                guard data.count > 0 else {
                    messageBody = nil
                    state = .end
                    continue
                }
                if let headerContentLength = headerContentLength {
                    messageBody = String(data: data.subdata(in: 0..<headerContentLength), encoding: encoding)!
                    data.removeSubrange(0..<headerContentLength)
                    state = .end
                    continue
                }
                if headerTransferEncodingChunked {
                    fatalError("TODO")
                }

                messageBody = String(data: data, encoding: encoding)!
                state = .end
                continue
            case .end:
                fatalError()
            }
        }

        return AwsSigv4OfficialTestSuite.Case.Request(
            method: method,
            requestURI: requestURI,
            httpVersion: httpVersion,
            messageHeaders: messageHeaders,
            messageBody: messageBody
        )
    }
}
