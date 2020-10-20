//
//  Book.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import Foundation

struct Book {
    let title: String
    let subtitle: String?
    let isbn: String
    let price: String
    let imageURL: URL?
    let url: URL?
}

extension Book: Decodable {
   
    private enum Key: String, CodingKey {
        case title
        case subtitle
        case isbn13
        case price
        case image
        case url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        do { title    = try container.decode(String.self, forKey: .title) }    catch { throw error }
        do { subtitle = try container.decode(String.self, forKey: .subtitle) } catch { subtitle = nil }
        do { isbn     = try container.decode(String.self, forKey: .isbn13) }   catch { throw error }
        do { price    = try container.decode(String.self, forKey: .price) }    catch { throw error }
        do { imageURL = try container.decode(URL.self,    forKey: .image) }    catch { imageURL = nil }
        do { url      = try container.decode(URL.self,    forKey: .url) }      catch { url = nil }
    }
}
