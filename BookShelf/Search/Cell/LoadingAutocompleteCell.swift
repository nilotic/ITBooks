//
//  LoadingAutocompleteCell.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/20.
//

import UIKit

final class LoadingAutocompleteCell: UITableViewCell {

    // MARK: - IBOutlet
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    static let identifier = "LoadingAutocompleteCell"
    
    
    
    // MARK: - Function
    // MARK: Public
    func update() {
        activityIndicatorView.startAnimating()
    }
}
