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
        return CGSize(width: startSize.width * 5.0 + padding * 4.0, height: startSize.width)
    }
    
    
    // MARK: Private
    private var containerView = UIView()
    private let startSize     = CGSize(width: 12.0, height: 12.0)
    private let padding: CGFloat = 2.0
    
    
    
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
            let startImageView = UIImageView(image: UIImage(systemName: "star.fill"))
            startImageView.frame     = CGRect(origin: CGPoint(x: CGFloat(i) * (startSize.width + padding), y: 0), size: startSize)
            startImageView.tintColor = .systemYellow
            
            let backgroundImageView = UIImageView(image: UIImage(systemName: "star.fill"))
            backgroundImageView.frame     = startImageView.frame
            backgroundImageView.tintColor = .systemGray
            
            containerView.addSubview(startImageView)
            
            addSubview(backgroundImageView)
            addSubview(containerView)
            
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive   = true
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            containerView.topAnchor.constraint(equalTo: topAnchor).isActive           = true
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive     = true
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
        ratingMask.frame = CGRect(x: 0, y: 0, width: startSize.width * rounded + padding * (rounded - 1), height: containerView.frame.height)
        ratingMask.backgroundColor = UIColor.green.cgColor
        
        containerView.layer.mask = ratingMask
    }
}
    
