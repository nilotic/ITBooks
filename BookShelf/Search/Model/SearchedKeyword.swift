//
//  SearchedKeyword.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/21.
//

import Foundation

struct SearchedKeyword: Codable {
    let keyword: String
    let currentPage: UInt
    let count: UInt
    let totalCount: UInt
}
