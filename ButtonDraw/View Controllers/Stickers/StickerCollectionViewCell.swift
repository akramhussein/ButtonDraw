//
//  StickerCollectionViewCell.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 18/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit

class StickerCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            self.imageView?.contentMode = .scaleAspectFit
        }
    }
    
}
