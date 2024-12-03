//
//  NetworkManager.swift
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/7.
//

import Foundation

let ipinfoToken: String = "ce1438fe1f34a4"

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkFailure
}

class NetworkManager {
    
    static let shared = NetworkManager()
    private let session = URLSession.shared
    
    private init() {}
    
    /// 通用请求方法
    func request<T: Decodable>(
        urlString: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // 构建 URL
        guard var urlComponents = URLComponents(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // 处理 GET 请求的 URL 参数
        if method == .get, let parameters = parameters {
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        // 确保 URL 是有效的
        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        // 创建 URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        
        // 处理 POST 和 PUT 的请求体
        if (method == .post || method == .put), let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                completion(.failure(.decodingError))
                return
            }
        }
        
        // 创建请求任务
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error as NSError?, error.domain == NSURLErrorDomain {
                completion(.failure(.networkFailure))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(.decodingError))
            }
        }
        
        // 开始请求任务
        task.resume()
    }
    
    /// GET 请求
    func get<T: Decodable>(
        urlString: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(urlString: urlString, method: .get, parameters: parameters, headers: headers, completion: completion)
    }
    
    /// POST 请求
    func post<T: Decodable>(
        urlString: String,
        parameters: [String: Any],
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(urlString: urlString, method: .post, parameters: parameters, headers: headers, completion: completion)
    }
    
    /// PUT 请求
    func put<T: Decodable>(
        urlString: String,
        parameters: [String: Any],
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(urlString: urlString, method: .put, parameters: parameters, headers: headers, completion: completion)
    }
    
    /// DELETE 请求
    func delete<T: Decodable>(
        urlString: String,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(urlString: urlString, method: .delete, headers: headers, completion: completion)
    }
}

