public struct AwsSigv4OfficialTestSuite {
    public struct Case {
        public let name: String

        public let req: String
        public let creq: String
        public let sts: String
        public let authz: String
        public let sreq: String
    }

    public let credentialScope: String
    public let secretKey: String
    public let cases: [Case]
}
