//
//  DetailViewController.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/20.
//

import UIKit

final class DetailViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var ratingView: RatingView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    @IBOutlet private var isbnLabel: UILabel!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var imageActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    
    
    // MARK: - Value
    // MARK: Public
    let dataManager = DetailDataManager()
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveDetail(notification:)), name: DetailNotificationName.detail, object: nil)
        
        guard dataManager.requestDetail() == true else { return }
        activityIndicatorView.startAnimating()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: - Function
    // MARK: Private
    private func update() {
        guard let data = dataManager.detail else {
            Toast.show(message: NSLocalizedString("Please check your network connection or try again.", comment: ""))
            return
        }
        
        scrollView.isHidden = false
        
        // Image
        imageActivityIndicatorView.startAnimating()
        ImageDataManager.shared.download(url: ImageURL(url: data.imageURL, hash: hash)) { (url, image) in
            DispatchQueue.main.async {
                self.imageActivityIndicatorView.stopAnimating()
                self.imageView.image = image
            }
        }
        
        
        // Rating
        ratingView.rating = data.rating
        
        
        // Labels
        titleLabel.text    = data.title
        subtitleLabel.text = data.subtitle
        priceLabel.text    = data.price
        isbnLabel.text     = "ISBN: \(data.isbn13)"
        
        
        // Info
        updateInformation()
        
        
        // Description
        descriptionLabel.text = data.description
    }
    
    
    private func updateInformation() {
        var descriptionParagraphStyle: NSMutableParagraphStyle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment         = .left
            paragraphStyle.lineBreakMode     = .byWordWrapping
            paragraphStyle.minimumLineHeight = 22.0
            paragraphStyle.maximumLineHeight = 22.0
            paragraphStyle.paragraphSpacing  = 10.0
            paragraphStyle.headIndent        = 12.0
            return paragraphStyle
        }
        
        var descriptionAttributes: [NSAttributedString.Key : Any] {
            return [.font            : UIFont.systemFont(ofSize: 16.0),
                    .foregroundColor : UIColor(named: "title") ?? #colorLiteral(red: 0.1254901961, green: 0.1411764706, blue: 0.1607843137, alpha: 1),
                    .paragraphStyle  : descriptionParagraphStyle]
        }
        
        var dotString: NSMutableAttributedString {
            return NSMutableAttributedString(string: "• ", attributes: [.font            : UIFont.systemFont(ofSize: 10.0),
                                                                        .foregroundColor : UIColor(named: "title") ?? #colorLiteral(red: 0.1254901961, green: 0.1411764706, blue: 0.1607843137, alpha: 1),
                                                                        .kern            : 2.1,
                                                                        .baselineOffset  : 4.0,
                                                                        .paragraphStyle  : descriptionParagraphStyle])
        }
        guard let data = dataManager.detail else { return }
        let mutableAttributedString = NSMutableAttributedString()
        
        mutableAttributedString.append(dotString)
        mutableAttributedString.append(NSAttributedString(string: "Authors: \(data.authors)\n", attributes: descriptionAttributes))
        
        mutableAttributedString.append(dotString)
        mutableAttributedString.append(NSAttributedString(string: "Publisher: \(data.publisher)\n", attributes: descriptionAttributes))
        
        mutableAttributedString.append(dotString)
        mutableAttributedString.append(NSAttributedString(string: "Language: \(data.language)\n", attributes: descriptionAttributes))
        
        mutableAttributedString.append(dotString)
        mutableAttributedString.append(NSAttributedString(string: "Pages: \(data.pages)\n", attributes: descriptionAttributes))
        
        mutableAttributedString.append(dotString)
        mutableAttributedString.append(NSAttributedString(string: "Year: \(data.year)\n", attributes: descriptionAttributes))
        
        infoLabel.attributedText = mutableAttributedString
    }
    
    
    
    // MARK: - Notification
    @objc private func didReceiveDetail(notification: Notification) {
        DispatchQueue.main.async { self.activityIndicatorView.stopAnimating() }
        
        guard notification.object == nil else {
            Toast.show(message: (notification.object as? ResponseDetail)?.message ?? NSLocalizedString("Please check your network connection or try again.", comment: ""))
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        
        DispatchQueue.main.async { self.update() }
    }
    
    
    
    // MARK: - Event
    // MARK: Link
    @IBAction private func linkButtonTouchUpInside(_ sender: UIButton) {
        guard let url = dataManager.detail?.url, UIApplication.shared.canOpenURL(url) == true else {
            Toast.show(message: NSLocalizedString("Invalid URL \(dataManager.detail?.url?.absoluteString ?? "")", comment: ""))
            return
        }
        
        DispatchQueue.main.async { UIApplication.shared.open(url) }
    }
    
    // MARK: Back
    @IBAction private func backBarButtonItemAction(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async { self.navigationController?.popViewController(animated: true) }
    }
}
