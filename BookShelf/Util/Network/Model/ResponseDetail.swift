//
//  ResponseDetail.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import Foundation

struct ResponseDetail {
    var statusCode: HTTPStatusCode?
    var message: String?
    let code: Int?
}

extension ResponseDetail {
    
    init(message: String?) {
        self.message = message
        code = nil
    }
    
    init(statusCode: HTTPStatusCode?,  message: String?) {
        self.statusCode = statusCode
        self.message    = message
        code = nil
    }
}

extension ResponseDetail: Decodable {
    
    private enum Key: String, CodingKey {
        case message
        case code
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        do { code = try container.decode(Int.self, forKey: .code) } catch { code = nil }
        
        do {
            guard code != -99999 else {
                message = nil
                return
            }
            message = try container.decode(String.self, forKey: .message)
            
        } catch { message = nil }
        
    }
}
