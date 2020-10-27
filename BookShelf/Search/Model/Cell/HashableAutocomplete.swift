//
//  HashableAutocomplete.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/27.
//

import Foundation

struct HashableAutocomplete {
    var data: Autocomplete
    let uuid = UUID()
}

extension HashableAutocomplete: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid.uuidString)
    }
}

extension HashableAutocomplete: Equatable {

    static func ==(lhs: HashableAutocomplete, rhs: HashableAutocomplete) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
