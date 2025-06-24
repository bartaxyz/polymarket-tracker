import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case badServerResponse(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
}

protocol APIClientProtocol {
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?
    ) async throws -> T
    
    func requestData(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?
    ) async throws -> Data
    
    func requestJSON(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?
    ) async throws -> Any
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

class APIClient: APIClientProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> T {
        let data = try await requestData(url: url, method: method, headers: headers, body: body)
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func requestData(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.badServerResponse(statusCode: 0)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.badServerResponse(statusCode: httpResponse.statusCode)
            }
            
            return data
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("Request cancelled: \(url.absoluteString)")
            }
            
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    func requestJSON(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Any {
        let data = try await requestData(url: url, method: method, headers: headers, body: body)
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw APIError.decodingError(error)
        }
    }
}