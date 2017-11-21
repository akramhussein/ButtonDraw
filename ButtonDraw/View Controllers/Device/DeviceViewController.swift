//
//  DeviceViewController.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 04/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit
import MBProgressHUD

final class DeviceViewController: UIViewController {

    public static let MinX = 12.5
    public static let MinY = 12.5
    public static let MaxX = 323.5
    public static let MaxY = 352.5
    
    public enum Direction: String {
        case north, northEast, east, southEast, south, southWest, west, northWest
        
        var image: UIImage {
            return UIImage(named: self.rawValue)!
        }
        
        var next: Direction {
            if let index = Direction.all.index(of: self), (index + 1) < Direction.all.count {
                return Direction.all[index + 1]
            }
            return Direction.all.first!
        }
        
        /// x, y
        var offset: (Double, Double) {
            switch self {
            case .north:
                return (0, 1)
            case .northEast:
                return (1, 1)
            case .east:
                return (1, 0)
            case .southEast:
                return (1, -1)
            case .south:
                return (0, -1)
            case .southWest:
                return (-1, -1)
            case .west:
                return (-1, 0)
            case .northWest:
                return (-1, 1)
            }
        }
        
        public static var all: [Direction] {
            return [
                .north,
                .northEast,
                .east,
                .southEast,
                .south,
                .southWest,
                .west,
                .northWest
            ]
        }
        
    }
    
    // MARK: UI Outlets

    @IBOutlet weak var button: UIButton! {
        didSet {
            self.button.backgroundColor = .clear
            
            let gesture = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(DeviceViewController.longPressGesture(recognizer:)))
            gesture.minimumPressDuration = 0.05
            self.button.addGestureRecognizer(gesture)
        }
    }
    
    var nextPenImage: UIImage {
        return UIImage(named: "pen_\(self.penPosition.next.rawValue)")!.withRenderingMode(.alwaysTemplate)
    }
    
    var actionButtonGesture: UILongPressGestureRecognizer!
    
    @IBOutlet weak var actionButton: UIButton! {
        didSet {
            self.actionButton.backgroundColor = .blue
            self.actionButton.layer.cornerRadius = 6.0
            self.actionButton.tintColor = .white
            self.actionButton.adjustsImageWhenHighlighted = false
            self.actionButton.contentHorizontalAlignment = .fill
            self.actionButton.contentVerticalAlignment = .fill
            self.actionButton.imageView?.contentMode = .scaleAspectFit
            self.actionButton.imageEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20)
        
        }
    }

    private var allButtons = [UIButton]()

    // MARK: Properties
    var hud: MBProgressHUD?

    private var connection: BluetoothConnection!
    private var mBot: MBot!
    private var device: BluetoothDevice?
    private var arrowImage = UIImage(named: "Arrow")!

    private var x: Double = DeviceViewController.MinX
    private var y: Double = DeviceViewController.MinY
    
    private var penPosition: MakeblockRobot.PenPosition = .up {
        didSet {
            let image = UIImage(named: "pen_\(self.penPosition.rawValue)")
            self.actionButton.setImage(image, for: .normal)
            self.actionButton.backgroundColor = (self.penPosition == .up) ? .blue : .red
            self.mBot.sendXYPen(self.penPosition)
        }
    }

    private var drawTimer = Timer()
    
    private var enterTimer = Timer() // enter keyboard button
    private var spaceTimer = Timer() // space keyboard button
    

    
    private var buttonTimer = Timer() // main button

    private var currentDirection: Direction! {
        didSet {
            self.button.setImage(self.currentDirection.image, for: .normal)
        }
    }

    var drawSpeed: Double = 0.10
    var drawPointFactor: Double = 2.0
    
    var scanningSpeed: Double {
        let speed = Defaults.getUserDefaultsValueForKeyAsDouble(Key.ScanningSpeed)
        if speed == 0.0 {
            Defaults.setUserDefaultsKey(Key.ScanningSpeed, value: 1.0)
            return 1.0
        }
        return speed
    }
    
    var stickerDelay: Double {
        let speed = Defaults.getUserDefaultsValueForKeyAsDouble(Key.StickerDelay)
        if speed == 0.0 {
            Defaults.setUserDefaultsKey(Key.StickerDelay, value: 1.0)
            return 1.0
        }
        return speed
    }

    var scanning: Bool = false {
        didSet {
            if self.scanning {
                self.buttonTimer.invalidate()
                self.buttonTimer = Timer.scheduledTimer(timeInterval: self.scanningSpeed,
                                                        target: self,
                                                        selector: #selector(DeviceViewController.nextDirection(_:)),
                                                        userInfo: nil,
                                                        repeats: true)
            } else {
                self.buttonTimer.invalidate()
            }
        }
    }

    
    var drawingSticker = false {
        didSet {
            self.scanning = !self.drawingSticker
            
            if !self.drawingSticker {
                self.penPosition = .up
                
                if let hud = self.hud {
                    hud.hide(animated: true, afterDelay: 1.0)
                }
            }
        }
    }
    
    var coordinatesToDraw = [[(Double, Double)]]()
    var newPath = false
    var height = 25.0
    var width = 25.0
    
    
    var commands: [UIKeyCommand] = {
        return [
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(DeviceViewController.enterPressed(_:))),
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(DeviceViewController.spacePressed(_:))),
        ]
    }()

    override var keyCommands: [UIKeyCommand]? {
        return self.commands
    }

    // MARK: ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "\(self.device?.name ?? "Drawing")"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(DeviceViewController.backPressed(_:)))

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(DeviceViewController.settingsPressed(_:)))

        self.currentDirection = .north
        self.mBot.sendXYReset()
//        self.penPosition = .up
//        self.mBot.sendXYDraw(x: DeviceViewController.MinX, y: DeviceViewController.MinY)
        
        self.actionButtonGesture = UILongPressGestureRecognizer(target: self,
                                                               action: #selector(DeviceViewController.longPressGestureActionButton(recognizer:)))
        
        self.actionButtonGesture.minimumPressDuration = self.stickerDelay
        self.actionButton.addGestureRecognizer(self.actionButtonGesture)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.scanning = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.drawingSticker = false
    }
    
    // MARK: Init

    init(connection: BluetoothConnection, device: BluetoothDevice?) {
        self.connection = connection
        self.device = device
        self.mBot = MBot(connection: self.connection)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: UI Actions
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        print("Setting pen to: \(self.penPosition.next.rawValue)")
        self.penPosition = self.penPosition.next
    }
    
    // MARK: Gestures

    @objc func longPressGesture(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            print("Start drawing")
            self.drawTimer.invalidate()
            self.scanning = false
            self.activateCurrentDirection(self)
            self.drawTimer = Timer.scheduledTimer(timeInterval: self.drawSpeed,
                                              target: self,
                                              selector: #selector(DeviceViewController.activateCurrentDirection(_:)),
                                              userInfo: nil,
                                              repeats: true)
        } else if recognizer.state == .ended {
            print("Stop drawing")
            self.drawTimer.invalidate()
            self.scanning = true
        }
    }
    
    @objc func longPressGestureActionButton(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            let vc = StickersViewController { (sticker) in
                self.navigationController?.popViewController(animated: true)
                self.drawSticker(sticker: sticker)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func nextDirection(_ sender: Any) {
        self.currentDirection = self.currentDirection.next
    }

    @objc func activateCurrentDirection(_ sender: Any) {
        let x = self.x + (self.currentDirection.offset.0 * self.drawPointFactor)
        let y = self.y + (self.currentDirection.offset.1 * self.drawPointFactor)
        
        if (x < 0 && y < 0) {
            print("x: 0, y: 0 - Out of bounds")
            return
        }
        if (x > DeviceViewController.MaxX && y > DeviceViewController.MaxY) {
            print("x: 3600, y: 3600 - Out of bounds")
            return
        }
        
        var dX = x
        var dY = y
        
        // Cap values
        
        if x < DeviceViewController.MinX {
            dX = DeviceViewController.MinX
        }
        if x > DeviceViewController.MaxX {
            dX = DeviceViewController.MaxX
        }
        if y < DeviceViewController.MinY {
            dY = DeviceViewController.MinY
        }
        if y > DeviceViewController.MaxY {
            dY = DeviceViewController.MaxY
        }
        
        self.x = dX
        self.y = dY

        print("Drawing to x: \(self.x), y: \(self.y)")
        self.mBot.sendXYDraw(x: self.x, y: self.y)
    }
    
    func drawSticker(sticker: Sticker) {
        print("Drawing \(sticker.rawValue)")
        
        sticker.paths.keys.sorted(by: <).forEach {
            let path = sticker.paths[$0]
            self.coordinatesToDraw.append(path!)
        }
        self.penPosition = .up
        self.newPath = true
        self.drawingSticker = true
        
        self.hud = MBProgressHUD.createImageHUD(view: self.view, message: "Drawing...", image: sticker.image)
        self.startDrawingSticker(self)
    }
    
    func startDrawingSticker(_ sender: Any) {
        if !self.drawingSticker {
            print("Stopped drawing")
            self.penPosition = .up
            self.mBot.sendXYDraw(x: self.x, y: self.y)
            return
        }
        
        if self.coordinatesToDraw.isEmpty {
            print("Finished drawing")
            self.drawingSticker = false
            self.mBot.sendXYDraw(x: self.x, y: self.y)
            return
        }
        
        let coords = self.coordinatesToDraw.first!
        let coord = coords.first!
        
        print("X: \(coord.0), Y: \(coord.1)")
        let x = self.x - (self.width / 2) + coord.0
        let y = self.y + (self.height / 2) - coord.1
        
        // Move to new path first
        if self.newPath {
            self.mBot.sendXYDraw(x: x, y: y)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.drawSpeed) {
                self.penPosition = .down
                self.newPath = false
                self.startDrawingSticker(self) // recurse function
            }
            return
        }
        
        // Remove first co-ordinate
        self.coordinatesToDraw[0].remove(at: 0)
        
        // If the path is now empty, remove the path itself
        if self.coordinatesToDraw[0].isEmpty {
            self.coordinatesToDraw.remove(at: 0)
            
            // Draw last point and then lift pen
            self.mBot.sendXYDraw(x: x, y: y)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.drawSpeed ) {
                self.penPosition = .up
                self.newPath = true
                self.startDrawingSticker(self) // recurse function
            }
            return
        }
        
        // Draw next point
        self.mBot.sendXYDraw(x: x, y: y)
        DispatchQueue.main.asyncAfter(deadline: .now() + self.drawSpeed) { 
            self.startDrawingSticker(self) // recurse function
        }
    }
        
    @objc func backPressed(_ sender: Any) {
        self.connection.disconnect()
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func settingsPressed(_ sender: Any) {
        let vc = DeviceSettingsViewController(scanningSpeed: self.scanningSpeed, stickerDelay: self.stickerDelay) { scanningSpeed, stickerDelay in
            Defaults.setUserDefaultsKey(Key.ScanningSpeed, value: scanningSpeed)
            Defaults.setUserDefaultsKey(Key.StickerDelay, value: stickerDelay)
            
            self.actionButtonGesture.minimumPressDuration = self.stickerDelay
            
            self.buttonTimer.invalidate()
            self.buttonTimer = Timer.scheduledTimer(timeInterval: self.scanningSpeed,
                                                    target: self,
                                                    selector: #selector(DeviceViewController.nextDirection(_:)),
                                                    userInfo: nil,
                                                    repeats: true)
            
            self.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: Access Switch

    override var canBecomeFirstResponder: Bool {
        return true
    }

    @objc public func enterPressed(_ command: UIKeyCommand) {
        if self.drawingSticker { return }
        
        self.scanning = false
        self.enterTimer.invalidate()
        
        if !self.drawTimer.isValid {
            print("Access Switch: Enter First Press")
            self.activateCurrentDirection(self)
            self.drawTimer = Timer.scheduledTimer(timeInterval: self.drawSpeed,
                                                  target: self,
                                                  selector: #selector(DeviceViewController.activateCurrentDirection(_:)),
                                                  userInfo: nil,
                                                  repeats: true)
        } else {
             print("Access Switch: Enter Additional Press")
        }
        
        // re-init timer
        self.enterTimer = Timer.scheduledTimer(timeInterval: self.drawSpeed,
                                                  target: self,
                                                  selector: #selector(DeviceViewController.enterReleased(_:)),
                                                  userInfo: nil,
                                                  repeats: false)

    }
    
    @objc public func enterReleased(_ sender: Any) {
        print("Action Switch: Enter Released")
        self.enterTimer.invalidate()
        self.drawTimer.invalidate()
        self.scanning = true
    }
    
    var spaceButtonMultipleTrigger = false
    
    @objc public func spacePressed(_ command: UIKeyCommand) {
        if self.drawingSticker { return }
        print("Access Switch: Space pressed")
        
        if spaceTimer.isValid {
            self.spaceButtonMultipleTrigger = true
        }
        
        self.spaceTimer.invalidate()
        self.spaceTimer = Timer.scheduledTimer(timeInterval: self.stickerDelay,
                                               target: self,
                                               selector: #selector(DeviceViewController.spaceReleased(_:)),
                                               userInfo: nil,
                                               repeats: false)
        
    }
    
    @objc public func spaceReleased(_ sender: Any) {
        if !self.spaceButtonMultipleTrigger {
            self.actionButtonPressed(self)
        } else {
            let vc = StickersViewController { (sticker) in
                self.navigationController?.popViewController(animated: true)
                self.drawSticker(sticker: sticker)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        self.spaceButtonMultipleTrigger = false
    }
}
