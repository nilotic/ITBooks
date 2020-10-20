//
//  BooksResponse.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import Foundation

struct BooksResponse {
    let books: [Book]
    let total: UInt
    let page: UInt
    let error: String?
}

extension BooksResponse: Decodable {
   
    private enum Key: String, CodingKey {
        case books
        case error
        case total
        case page
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        do { books = try container.decode([Book].self, forKey: .books) } catch { books = [] }
        do { error = try container.decode(String.self, forKey: .error) } catch { self.error = nil }

        do { total = UInt(try container.decode(String.self, forKey: .total)) ?? 0 } catch { total = 0 }
        do { page  = UInt(try container.decode(String.self, forKey: .page)) ?? 0 } catch { page = 0 }
    }
}
