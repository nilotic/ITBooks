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
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var imageActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    
    
    // MARK: - Value
    // MARK: Public
    let dataManager = DetailDataManager()
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setTextView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveDetail(notification:)),           name: DetailNotificationName.detail,            object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        guard dataManager.requestDetail() == true else { return }
        activityIndicatorView.startAnimating()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: - Function
    // MARK: Private
    private func setTextView() {
        textView.layer.cornerRadius = 4.0
        textView.layer.borderWidth  = 1.0
        textView.layer.borderColor  = #colorLiteral(red: 0.9215686275, green: 0.9215686275, blue: 0.9215686275, alpha: 1)
        
        textView.textContainerInset = UIEdgeInsets(top: 14.0, left: 9.0, bottom: 16.0, right: 9.0)
    }
    
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
    
    @objc private func didReceiveKeyboardWillShow(notification: Notification) {
        scrollViewBottomConstraint.constant = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero).height
        DispatchQueue.main.async { self.view.layoutIfNeeded() }
    }
    
    @objc private func didReceiveKeyboardWillHide(notification: Notification) {
        scrollViewBottomConstraint.constant = 0
        DispatchQueue.main.async { self.view.layoutIfNeeded() }
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



// MARK: - UITextView Delegate
extension DetailViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        DispatchQueue.main.async {
            self.scrollView.setContentOffset(CGPoint(x: 0, y: self.scrollView.contentSize.height - textView.frame.height), animated: true)
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        dataManager.note = textView.text
    }
}
