//
//  RatingView.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/20.
//

import UIKit

final class RatingView: UIView {
    
    // MARK: - Value
    // MARK: Public
    var rating: Float = 0 {
        didSet { update() }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: startSize.width * 5.0 + 2.0 * 4.0, height: startSize.width)
    }
    
    
    // MARK: Private
    private var imageViews = [UIImageView]()
    private let startSize  = CGSize(width: 12.0, height: 12.0)
    
    
    
    // MARK: - Initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setView()
    }
    
    override func prepareForInterfaceBuilder() {
        setView()
    }

    
    
    // MARK: - Function
    // MARK: Private
    private func setView() {
        for i in 0..<5 {
            let imageView = UIImageView(image: UIImage(systemName: "star.fill"))
            imageView.frame = CGRect(origin: CGPoint(x: CGFloat(i) * (startSize.width + 2.0), y: 0), size: startSize)
            imageView.tintColor = .systemYellow
            
            imageViews.append(imageView)
            addSubview(imageView)
        }
        
        let ratingMask = CALayer()
        ratingMask.frame = CGRect(origin: .zero, size: frame.size)
        ratingMask.backgroundColor = UIColor.white.cgColor
        layer.mask = ratingMask
        
        backgroundColor = .clear
        clipsToBounds   = true
    }
    
    private func update() {
        let rounded = CGFloat(round(max(0, min(5, rating)) * 10) / 10)
        
        let ratingMask = CALayer()
        ratingMask.frame = CGRect(x: 0, y: 0, width: frame.width * rounded / 5.0, height: frame.height)
        ratingMask.backgroundColor = UIColor.green.cgColor
        
        layer.mask = ratingMask
    }
}
    
