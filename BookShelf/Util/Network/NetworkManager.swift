//
//  NetworkManager.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import Foundation
import UIKit

final class NetworkManager: NSObject {
    
    // MARK: - Singleton
    static let shared = NetworkManager()
    private override init() { super.init() }
    
    
    // MARK: - Value
    // MARK: Private
    private let encoder = JSONEncoder()
    
    
    // MARK: - Function
    // MARK: Public
    func request(urlRequest: URLRequest, delegateQueue queue: OperationQueue? = nil, completion: @escaping (_ data: Response?) -> Void) -> Bool {
        log(.info, """
                   Request
                   URL
                   \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString ?? "")\n
                   HeaderField
                   \(urlRequest.allHTTPHeaderFields?.debugDescription ?? "")\n
                   Body
                   \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "")
                   \n\n
                   """)
        
        // Request
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
        
        if #available(iOS 13.0, *) {
            urlSession.configuration.allowsConstrainedNetworkAccess = false
            urlSession.configuration.allowsExpensiveNetworkAccess   = true
        }
        
        urlSession.dataTask(with: urlRequest, completionHandler: { data, urlResponse, error in
            let response = Response(data: data, urlResponse: urlResponse as? HTTPURLResponse, error: error)
            self.handle(urlRequest: urlRequest, response: response)
            completion(response)
            
            urlSession.finishTasksAndInvalidate()
        }).resume()
        
        return true
    }
    
    func request<T: Encodable>(urlRequest: URLRequest, requestData: T, delegateQueue queue: OperationQueue? = nil, completion: @escaping (_ requestData: T, _ data: Response?) -> Void) -> Bool {
        guard let request = encode(urlRequest: urlRequest, requestData: requestData) else { return false }
        
        log(.info, """
                   Request
                   URL
                   \(urlRequest.httpMethod ?? "") \(request.url?.absoluteString ?? "")\n
                    HeaderField
                   \(request.allHTTPHeaderFields?.debugDescription ?? "")\n
                   Body
                   \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")
                   \n\n
                   """)
        
        // Request
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
        
        if #available(iOS 13.0, *) {
            urlSession.configuration.allowsConstrainedNetworkAccess = false
            urlSession.configuration.allowsExpensiveNetworkAccess   = true
        }
        
        urlSession.dataTask(with: request, completionHandler: { data, urlResponse, error in
            let response = Response(data: data, urlResponse: urlResponse as? HTTPURLResponse, error: error)
            self.handle(urlRequest: urlRequest, response: response)
            completion(requestData, response)
            
            urlSession.finishTasksAndInvalidate()
        }).resume()
        
        return true
    }
    
    func encode<T: Encodable>(urlRequest: URLRequest, requestData: T) -> URLRequest? {
        var request = urlRequest
        
        guard let httpMethod = HTTPMethod(request: request) else {
            log(.error, "HTTP method is invalid.")
            return nil
        }
        
        switch httpMethod {
        case .get, .delete:
            guard let urlComponets = urlComponets(from: request.url, data: requestData) else {
                log(.error, "Failed to get a query.")
                return nil
            }
            request.url = urlComponets.url  // Insert parameters to the url
            
        case .put:
            if let contentType = request.value(forHTTPHeaderField: HTTPHeaderField.contentType.rawValue) {
                if contentType.range(of: HTTPHeaderValue.urlEncoded.rawValue) != nil {
                    request.httpBody = urlComponets(from: request.url, data: requestData)?.query?.data(using: .utf8, allowLossyConversion: false)       // Insert parameters to the body
                    
                } else if contentType.hasPrefix(HTTPHeaderValue.applicationJSON.rawValue) {
                    do { request.httpBody = try encoder.encode(requestData) } catch { return nil }                                                      // Insert parameters to the body
                }
                
            } else {
                request.httpBody = urlComponets(from: request.url, data: requestData)?.query?.data(using: .utf8)                                        // Insert parameters to the body
            }
            
        case .post:
            if let contentType = request.value(forHTTPHeaderField: HTTPHeaderField.contentType.rawValue) {
                if contentType.range(of: HTTPHeaderValue.urlEncoded.rawValue) != nil {
                    request.httpBody = urlComponets(from: request.url, data: requestData)?.query?.data(using: .utf8, allowLossyConversion: false)       // Insert parameters to the body
                    
                } else if contentType.hasPrefix(HTTPHeaderValue.applicationJSON.rawValue) {
                    do { request.httpBody = try encoder.encode(requestData) } catch { return nil }                                                      // Insert parameters to the body
                }
                
            } else {
                request.httpBody = urlComponets(from: request.url, data: requestData)?.query?.data(using: .utf8)                                        // Insert parameters to the body
            }
        }
    
        return request
    }
    
    
    // MARK: Private
    private func urlComponets<T: Encodable>(from url: URL?, data: T) -> URLComponents? {
        guard let string = url?.absoluteString, var urlComponent = URLComponents(string: string) else { return nil }
        
        do {
            guard var jsonData = try JSONSerialization.jsonObject(with: encoder.encode(data), options: .mutableContainers) as? [String : Any] else { return nil }
            
            // Remove null container
            for key in jsonData.keys.filter({ jsonData[$0] is NSNull }) { jsonData.removeValue(forKey: key) }
            
            var queryItems = [URLQueryItem]()
            for (key, value) in jsonData {
                switch value {
                case let list as [Any]:     list.forEach { queryItems.append(URLQueryItem(name: key, value: "\($0)")) }
                default:                    queryItems.append(URLQueryItem(name: key, value: "\(value)"))
                }
            }
            
            urlComponent.queryItems = queryItems.isEmpty == false ? queryItems : nil
            return urlComponent
            
        } catch {
            return nil
        }
    }
    
    private func handleSSL(_ session: Foundation.URLSession, challenge: URLAuthenticationChallenge) -> Bool {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            log(.error, "Failed to get a authenticationMethod.")
            return false
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            log(.error, "Failed to set trust policies.")
            return false
        }
        
        if #available(iOS 13, *) {
            var error: CFError? = nil
            guard SecTrustEvaluateWithError(serverTrust, &error) == true, error == nil else {
                log(.error, "Failed to check server trust. \(error?.localizedDescription ?? "")")
                return false
            }
            
        } else {
            var secTrustResultType = SecTrustResultType.invalid
            guard SecTrustEvaluate(serverTrust, &secTrustResultType) == errSecSuccess else {
                log(.error, "Failed to check server trust.")
                return false
            }
        }
        
        return true
    }
    
    private func handle(urlRequest: URLRequest, response: Response) {
        guard let urlResponse = response.urlResponse, let statusCode = HTTPStatusCode(rawValue: urlResponse.statusCode), response.error == nil else {
            log(.error, "Failed to get responseData. Error Description: \(response.error.debugDescription)")
            return
        }
        
        switch statusCode {
        case .ok, .created, .accepted:
            break
       
        case .badRequest:
            guard let code = response.detail?.code else { break }
            log(.error, code)

        case .unauthorized:
            log(.info, "Log Out")
            break
            
        case .forbidden:
            guard let code = response.detail?.code else { break }
            log(.error, code)
            
        case .preconditionFailed:
            guard let code = response.detail?.code else { return }
            log(.error, code)
            
        case .serviceUnavailable:
            guard let code = response.detail?.code else { return }
            log(.error, code)
            
        default:
            break
        }
        
        log(statusCode == .ok ? .info : .error, """
                                                Response
                                                HTTP status: \(statusCode.rawValue)
                                                URL: \(urlResponse.url?.absoluteString ?? "")\n
                                                HeaderField
                                                \(urlResponse.allHeaderFields.debugDescription))\n
                                                Data
                                                \(String(data: response.data ?? Data(), encoding: .utf8) ?? "")
                                                \n
                                                """ )
    }
}



// MARK: - NSURLSession Delegate
extension NetworkManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard handleSSL(session, challenge: challenge) == true, let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        session.invalidateAndCancel()
    }
}

