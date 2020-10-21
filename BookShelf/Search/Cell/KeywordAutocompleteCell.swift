//
//  KeywordAutocompleteCell.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/21.
//

import UIKit

final class KeywordAutocompleteCell: UITableViewCell {

    // MARK: - IBOutlet
    @IBOutlet private var keywordLabel: UILabel!
    
    
    
    // MARK: - Value
    // MARK: Public
    static let identifier = "KeywordAutocompleteCell"


    
    // MARK: - Function
    // MARK: Public
    func update(data: KeywordAutocomplete) {
        keywordLabel.text = data.keyword
    }
}
