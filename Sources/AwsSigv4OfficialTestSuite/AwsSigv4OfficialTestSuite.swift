public struct AwsSigv4OfficialTestSuite {
    public struct Case {
        public struct Request {
            public let method: String
            public let requestURI: String
            public let httpVersion: String
            public let messageHeaders: [[String]]
            public let messageBody: String?
        }

        public let name: String

        public let req: Request
        public let creq: String
        public let sts: String
        public let authz: String
        public let sreq: Request
    }

    public let credentialScope: String
    public let secretKey: String
    public let cases: [Case]
}
