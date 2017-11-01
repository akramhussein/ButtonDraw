//
//  StickersViewController+UICollectionViewDataSource.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 18/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit

extension StickersViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Sticker.all.count
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCollectionViewCell.className, for: indexPath) as! StickerCollectionViewCell
        cell.imageView.image = Sticker.all[indexPath.row].image
        
        var highlight = false
        switch self.state {
        case .highlightRow:
            let topIndex = (self.highlightRowIndex + 1) * Int(StickersViewController.NumberOfCellsPerRow) - 1
            let bottomIndex = self.highlightRowIndex * Int(StickersViewController.NumberOfCellsPerRow)
            highlight = (indexPath.row >= bottomIndex) && (indexPath.row <= topIndex)
        case .highlightColumn:
            let itemIndex = (self.highlightColumnIndex % Int(StickersViewController.NumberOfCellsPerRow))
                          + (self.highlightRowIndex * Int(StickersViewController.NumberOfCellsPerRow))
            highlight = (indexPath.row == itemIndex)
        }
        
        if highlight {
            cell.backgroundColor = .coral
            cell.imageView.backgroundColor = .coral
            cell.imageView.tintColor = .white
        } else {
            cell.backgroundColor = .white
            cell.imageView.backgroundColor = .white
            cell.imageView.tintColor = .green
        }
        return cell
    }
}

