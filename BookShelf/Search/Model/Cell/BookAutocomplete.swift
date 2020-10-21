//
//  BookAutocomplete.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/20.
//

import Foundation

struct BookAutocomplete: Autocomplete {
    let title: String
    let subtitle: String?
    let price: String
    let isbn: String
    let imageURL: URL?
    let url: URL?
}

extension BookAutocomplete {
    
    init(data: Book) {
        title    = data.title
        subtitle = data.subtitle
        price    = data.price
        isbn     = data.isbn
        imageURL = data.imageURL
        url      = data.url
    }
    
    init(data: BookEntity) {
        title    = data.title ?? ""
        subtitle = data.subtitle
        price    = data.price ?? ""
        isbn     = data.isbn ?? ""
        imageURL = data.imageURL
        url      = data.url
    }
}
