//
//  ToastView.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import UIKit

final class ToastView: UIView {
    
    // MARK: - Value
    // MARK: Public
    var bottomConstraint: NSLayoutConstraint? = nil
    
    
    
    // MARK: - View Life Cycle
    override func layoutSubviews() {
        layer.masksToBounds = false
        layer.cornerRadius  = bounds.height / 2.0
    }
}
