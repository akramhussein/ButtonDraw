//
//  StickersViewController+UICollectionViewDelegate.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 18/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit

extension StickersViewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        self.completionHandler?(Sticker.all[indexPath.row])
        self.enterPressed(UIKeyCommand())
    }
}
