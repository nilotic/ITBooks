//
//  Response.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import Foundation

struct Response {
    let url: URL
    let headerFields: [AnyHashable : Any]
    let data: Data?
    let code: Int?
    let message: String?
    let statusCode: HTTPStatusCode
}

extension Response {
    
    init?(data: Data?, urlResponse: URLResponse?, error: Error?) {
        guard let urlResponse = urlResponse as? HTTPURLResponse, let url = urlResponse.url else { return nil }
        
        self.url          = url
        self.headerFields = urlResponse.allHeaderFields
        self.data         = data
    
        statusCode = HTTPStatusCode(rawValue: urlResponse.statusCode) ?? .none
        
        guard let data = data, let responseStatus = try? JSONDecoder().decode(ResponseStatus.self, from: data) else {
            message = error?.localizedDescription ?? NSLocalizedString("Please check your network connection or try again.", comment: "")
            code = nil
            return
        }
        
        message = responseStatus.message ?? error?.localizedDescription
        code    = responseStatus.code
    }
}

extension Response: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return """
                Response
                HTTP status: \(statusCode.rawValue)
                URL: \(url.absoluteString)\n
                HeaderField
                \(headerFields.debugDescription))\n
                Data
                \(String(data: data ?? Data(), encoding: .utf8) ?? "")
                \n
                """
    }
}
