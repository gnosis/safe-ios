//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol JSONRequest: Encodable {

    var httpMethod: String { get }
    var urlPath: String { get }

    associatedtype ResponseType: Decodable

}

public extension DateFormatter {

    public static let networkDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

}

public class JSONHTTPClient {

    public enum Error: Swift.Error {
        case networkRequestFailed(URLRequest, URLResponse?)
    }

    private typealias URLDataTaskResult = (data: Data?, response: URLResponse?, error: Swift.Error?)

    private let baseURL: URL
    private let logger: Logger?

    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter.networkDateFormatter
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }()

    public init(url: URL, logger: Logger? = nil) {
        baseURL = url
        self.logger = logger
    }

    public func execute<T: JSONRequest>(request: T) throws -> T.ResponseType {
        let urlRequest = try self.urlRequest(from: request)
        let result = send(urlRequest)
        let response: T.ResponseType = try self.response(from: urlRequest, result: result)
        return response
    }

    private func urlRequest<T: JSONRequest>(from jsonRequest: T) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(jsonRequest.urlPath)
        var request = URLRequest(url: url)
        request.httpMethod = jsonRequest.httpMethod
        request.httpBody = try jsonEncoder.encode(jsonRequest)
        if let str = String(data: request.httpBody!, encoding: .utf8) {
            logger?.debug(str)
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func send(_ request: URLRequest) -> URLDataTaskResult {
        var result: URLDataTaskResult
        let semaphore = DispatchSemaphore(value: 0)
        logger?.debug("Sending request \(request)")

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            result = (data, response, error)
            semaphore.signal()
        }
        dataTask.resume()
        semaphore.wait()
        logger?.debug("Received response \(result)")
        return result
    }

    private func response<T: Decodable>(from request: URLRequest, result: URLDataTaskResult) throws -> T {
        if let data = result.data, let rawResponse = String(data: data, encoding: .utf8) {
            logger?.debug(rawResponse)
        }
        if let error = result.error {
            throw error
        }
        guard let httpResponse = result.response as? HTTPURLResponse, httpResponse.statusCode / 100 == 2,
            let data = result.data else {
                throw Error.networkRequestFailed(request, result.response)
        }
        let response: T
        do {
            response = try JSONDecoder().decode(T.self, from: data)
        } catch let error {
            logger?.error("Failed to decode response: \(error)")
            throw error
        }
        return response
    }

}
