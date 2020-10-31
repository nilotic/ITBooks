//
//  BookAutocompleteCell.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/20.
//

import UIKit

final class BookAutocompleteCell: UITableViewCell {

    // MARK: - IBOutlet
    @IBOutlet private var bookImageView: UIImageView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var isbnLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    
    
    
    // MARK: - Value
    // MARK: Public
    static let identifier = "BookAutocompleteCell"
    
    // MARK: Private
    private var imageURL: ImageURL? = nil
    
    
    
    // MARK: - View Life Cycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        bookImageView.image = nil
        ImageDataManager.shared.cancelDownload(url: imageURL)
    }
    

    
    // MARK: - Function
    // MARK: Public
    func update(data: BookAutocomplete) {
        // Image
        imageURL = ImageURL(url: data.imageURL, hash: hash)
        activityIndicatorView.startAnimating()
        
        ImageDataManager.shared.download(url: imageURL) { [weak self] (url, image) in
            DispatchQueue.main.async {
                guard self?.imageURL == url else { return }
                self?.activityIndicatorView.stopAnimating()
                self?.bookImageView.image = image
            }
        }
        
        
        // Labels
        titleLabel.text    = data.title
        subtitleLabel.text = data.subtitle
        isbnLabel.text     = "ISBN: \(data.isbn)"
        priceLabel.text    = data.price
    }
}
