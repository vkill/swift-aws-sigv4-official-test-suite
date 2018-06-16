import XCTest
@testable import AwsSigv4OfficialTestSuite

final class AwsSigv4OfficialTestSuiteTests: XCTestCase {
    func testGeneratedContent() {
        XCTAssertEqual(AwsSigv4OfficialTestSuiteContent.suite.credentialScope, "AKIDEXAMPLE/20150830/us-east-1/service/aws4_request")
        XCTAssertEqual(AwsSigv4OfficialTestSuiteContent.suite.secretKey, "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY")
        let `case` = AwsSigv4OfficialTestSuiteContent.suite.cases.filter { $0.name == "post-sts-header-after" }.first!

        XCTAssertEqual(`case`.req.method, "POST")
        XCTAssertEqual(`case`.req.requestURI, "/")
        XCTAssertEqual(`case`.req.httpVersion, "HTTP/1.1")
        XCTAssertEqual(`case`.req.messageHeaders, [
            ["Host", "example.amazonaws.com"],
            ["X-Amz-Date", "20150830T123600Z"]
        ])
        XCTAssertEqual(`case`.req.messageBody, nil)

        XCTAssertEqual(`case`.creq, """
POST
/

host:example.amazonaws.com
x-amz-date:20150830T123600Z

host;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
""")
        XCTAssertEqual(`case`.sts, """
AWS4-HMAC-SHA256
20150830T123600Z
20150830/us-east-1/service/aws4_request
553f88c9e4d10fc9e109e2aeb65f030801b70c2f6468faca261d401ae622fc87
""")
        XCTAssertEqual(`case`.authz, """
AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5da7c1a2acd57cee7505fc6676e4e544621c30862966e37dddb68e92efbe5d6b
""")

        XCTAssertEqual(`case`.sreq.method, "POST")
        XCTAssertEqual(`case`.sreq.requestURI, "/")
        XCTAssertEqual(`case`.sreq.httpVersion, "HTTP/1.1")
        XCTAssertEqual(`case`.sreq.messageHeaders, [
            ["Host", "example.amazonaws.com"],
            ["X-Amz-Date", "20150830T123600Z"],
            ["X-Amz-Security-Token", "AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQWLWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGdQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA=="],
            ["Authorization", " AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5da7c1a2acd57cee7505fc6676e4e544621c30862966e37dddb68e92efbe5d6b"]
        ])
        XCTAssertEqual(`case`.sreq.messageBody, nil)
    }

    static var allTests = [
        ("testGeneratedContent", testGeneratedContent),
    ]
}
