import Testing
import Foundation
@testable import RickAndMortyDomain

@Suite(.serialized) struct URLSessionHTTPClientTests: ~Copyable {

    init() { URLProtocolStub.startInterceptingRequests() }
    deinit { URLProtocolStub.stopInterceptingRequests() }

    // MARK: - Test 1

    @Test func get_requestsCorrectURL() async {
        let url = anyURL()
        URLProtocolStub.stub(data: nil, response: nil, error: anyNSError())

        _ = await result(from: url)

        let observed = URLProtocolStub.observedRequests
        #expect(observed.count == 1)
        #expect(observed.first?.url == url)
    }

    // MARK: - Test 2

    @Test func get_requestsWithGETMethod() async {
        URLProtocolStub.stub(data: nil, response: nil, error: anyNSError())

        _ = await result(from: anyURL())

        #expect(URLProtocolStub.observedRequests.first?.httpMethod == "GET")
    }

    // MARK: - Test 3

    @Test func get_deliversErrorOnRequestError() async {
        let expectedError = anyNSError()
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)

        let outcome = await result(from: anyURL())

        switch outcome {
        case let .failure(receivedError as NSError):
            #expect(receivedError.domain == expectedError.domain)
            #expect(receivedError.code == expectedError.code)
        default:
            Issue.record("Expected failure, got \(String(describing: outcome))")
        }
    }

    // MARK: - Test 4

    @Test func get_deliversDataAndResponseOn200Response() async {
        let expectedData = Data("any data".utf8)
        let expectedResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: nil)

        let outcome = await result(from: anyURL())

        switch outcome {
        case let .success((data, response)):
            #expect(data == expectedData)
            #expect(response.statusCode == expectedResponse.statusCode)
        default:
            Issue.record("Expected success, got \(String(describing: outcome))")
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSessionHTTPClient(session: URLSession(configuration: configuration))
    }

    private func anyURL() -> URL { URL(string: "https://any-url.com")! }
    private func anyNSError() -> NSError { NSError(domain: "any", code: 0) }

    private func result(from url: URL) async -> Result<(Data, HTTPURLResponse), Error>? {
        await withCheckedContinuation { continuation in
            makeSUT().get(from: url) { continuation.resume(returning: $0) }
        }
    }
}

// MARK: - URLProtocolStub

final class URLProtocolStub: URLProtocol {
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    private static var _stub: Stub?
    private static var _observedRequests: [URLRequest] = []
    private static let lock = NSLock()

    static var observedRequests: [URLRequest] {
        lock.withLock { _observedRequests }
    }

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        lock.withLock { _stub = Stub(data: data, response: response, error: error) }
    }

    static func startInterceptingRequests() {
        lock.withLock { _observedRequests = [] }
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        lock.withLock {
            _stub = nil
            _observedRequests = []
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        URLProtocolStub.lock.withLock {
            URLProtocolStub._observedRequests.append(request)
        }
        let stub = URLProtocolStub.lock.withLock { URLProtocolStub._stub }

        if let data = stub?.data { client?.urlProtocol(self, didLoad: data) }
        if let response = stub?.response { client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed) }
        if let error = stub?.error { client?.urlProtocol(self, didFailWithError: error) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
