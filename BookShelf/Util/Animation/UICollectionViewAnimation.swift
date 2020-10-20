//
//  UICollectionViewAnimation.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import UIKit

struct UICollectionViewAnimationSet {
    let animation: UICollectionViewAnimation
    let items: [IndexPath]
    let sections: IndexSet
    
    enum UICollectionViewAnimation {
        case insertItems
        case insertSections
        case deleteItems
        case deleteSections
        case reloadItems
        case reloadSections
    }
}

extension UICollectionViewAnimationSet {
    
    init(animation: UICollectionViewAnimation, items: [IndexPath]) {
        self.animation = animation
        self.items     = items
        self.sections  = []
    }
    
    init(animation: UICollectionViewAnimation, sections: IndexSet) {
        self.animation = animation
        self.items     = []
        self.sections  = sections
    }
}

