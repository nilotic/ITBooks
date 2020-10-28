//
//  HashableAutocomplete.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/27.
//

import Foundation

struct HashableAutocomplete {
    let identifier = UUID()
    var data: Autocomplete
}

extension HashableAutocomplete: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension HashableAutocomplete: Equatable {

    static func ==(lhs: HashableAutocomplete, rhs: HashableAutocomplete) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
