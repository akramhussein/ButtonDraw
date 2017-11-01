//
//  CollectionView.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 18/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit
import Foundation

public extension UICollectionView {
    
    func registerCell(className: String) {
        self.register(UINib(nibName: className, bundle: nil),
                      forCellWithReuseIdentifier: className)
    }
    
    func registerFooter(className: String) {
        self.register(UINib(nibName: className, bundle: nil),
                      forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                      withReuseIdentifier: className)
    }
    
    func registerHeader(className: String) {
        self.register(UINib(nibName: className, bundle: nil),
                      forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                      withReuseIdentifier: className)
    }
    
}
