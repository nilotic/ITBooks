//
//  DetailResponse.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/20.
//

import Foundation

struct DetailResponse {
    let title: String
    let subtitle: String?
    let authors: String
    let publisher: String
    let language: String
    let isbn10: String
    let isbn13: String
    let pages: UInt
    let year: String
    let rating: Float
    let description: String
    let price: String
    let imageURL: URL?
    let url: URL?
}

extension DetailResponse: Decodable {
   
    private enum Key: String, CodingKey {
        case title
        case subtitle
        case authors
        case publisher
        case language
        case isbn10
        case isbn13
        case pages
        case year
        case rating
        case description = "desc"
        case price
        case imageURL = "image"
        case url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        
        do { title       = try container.decode(String.self, forKey: .title) }       catch { throw error }
        do { subtitle    = try container.decode(String.self, forKey: .subtitle) }    catch { subtitle = nil }
        do { authors     = try container.decode(String.self, forKey: .authors) }     catch { throw error }
        do { publisher   = try container.decode(String.self, forKey: .publisher) }   catch { throw error }
        do { language    = try container.decode(String.self, forKey: .language) }    catch { throw error }
        do { isbn10      = try container.decode(String.self, forKey: .isbn10) }      catch { throw error }
        do { isbn13      = try container.decode(String.self, forKey: .isbn13) }      catch { throw error }
        do { year        = try container.decode(String.self, forKey: .year) }        catch { throw error }
        do { description = try container.decode(String.self, forKey: .description) } catch { throw error }
        do { price       = try container.decode(String.self, forKey: .price) }       catch { throw error }
        do { imageURL    = try container.decode(URL.self,    forKey: .imageURL) }    catch { imageURL = nil }
        do { url         = try container.decode(URL.self,    forKey: .url) }         catch { url = nil }
        
        do { pages  = UInt(try container.decode(String.self, forKey: .pages)) ?? 0 }   catch { pages = 0 }
        do { rating = Float(try container.decode(String.self, forKey: .rating)) ?? 0 } catch { rating = 0 }
    }
}
