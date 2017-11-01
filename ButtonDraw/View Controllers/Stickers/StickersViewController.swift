//
//  StickersViewController.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 17/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit

public typealias StickersViewControllerCompletionHandler = ((_ sticker: Sticker) -> Void)

final class StickersViewController: UIViewController {
    
    public static let NumberOfCellsPerRow: CGFloat = 3.0
    public static let NumberOfCellsPerColumn: CGFloat = 4.0
    
    // MARK: State
    
    public enum State: String {
        case highlightRow
        case highlightColumn
    }
    
    // MARK: UI Actions
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            self.collectionView.backgroundColor = .clear
            
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.allowsMultipleSelection = true
            self.collectionView.layoutMargins = .zero
            
            // Cell
            self.collectionView.registerCell(className: StickerCollectionViewCell.className)
        }
    }
    
    // MARK: Properties
    
    var completionHandler: StickersViewControllerCompletionHandler?
    var state: State = .highlightRow
    
    var highlightTimer = Timer()
    var highlightRowIndex = 0
    var highlightColumnIndex = 0
    
    var scanningSpeed: Double {
        let speed = Defaults.getUserDefaultsValueForKeyAsDouble(Key.ScanningSpeed)
        if speed == 0.0 {
            Defaults.setUserDefaultsKey(Key.ScanningSpeed, value: 1.0)
            return 1.0
        }
        return speed
    }
    
    // MARK: Init
    
    init(completionHandler: StickersViewControllerCompletionHandler? = nil) {
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Stickers"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back",
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(StickersViewController.backPressed(_:)))
        
        self.state = .highlightRow
        self.highlightTimer = Timer.scheduledTimer(timeInterval: self.scanningSpeed,
                                                   target: self,
                                                   selector: #selector(StickersViewController.shiftHighlight(_:)),
                                                   userInfo: nil,
                                                   repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.highlightTimer.invalidate()
    }
    
    @objc  func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc  func shiftHighlight(_ sender: Any) {
        switch self.state {
        case .highlightRow:
            if self.highlightRowIndex == Int(StickersViewController.NumberOfCellsPerColumn) - 1 {
                self.highlightRowIndex = 0
            } else {
                self.highlightRowIndex += 1
            }
        case .highlightColumn:
            if self.highlightColumnIndex == Int(StickersViewController.NumberOfCellsPerRow) - 1 {
                self.highlightColumnIndex = 0
            } else {
                self.highlightColumnIndex += 1
            }
        }
//        print("\(self.highlightRowIndex):\(highlightColumnIndex)")
        self.collectionView.reloadData()
    }
    
    // MARK: Access Switch
    
    var commands: [UIKeyCommand] = {
        return [
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(DeviceViewController.enterPressed(_:))),
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(DeviceViewController.spacePressed(_:))),
            ]
    }()
    
    override var keyCommands: [UIKeyCommand]? {
        return self.commands
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func enterPressed(_ command: UIKeyCommand) {
        switch self.state {
        case .highlightRow:
            self.highlightColumnIndex = 0
            self.state = .highlightColumn
            self.collectionView.reloadData()
        case .highlightColumn:
            let index = (self.highlightColumnIndex % Int(StickersViewController.NumberOfCellsPerRow))
                        + (self.highlightRowIndex * Int(StickersViewController.NumberOfCellsPerRow))
            self.completionHandler?(Sticker.all[index])
            break
        }
    }
    
    @objc func spacePressed(_ command: UIKeyCommand) {
        print("Action Switch: Space Released")
    }
}

