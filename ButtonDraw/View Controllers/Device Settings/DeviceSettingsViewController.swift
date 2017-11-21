//
//  DeviceSettingsViewController.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 04/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit
import Eureka

class DeviceSettingsViewController: FormViewController {

    // MARK: Properties
    private var scanningSpeed: Double!
    private var stickerDelay: Double!
    
    private var completionHandler: ((Double, Double) -> Void)?

    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back",
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(DeviceSettingsViewController.backPressed(_:)))

        form +++ Section("")

            <<< DecimalRow("scanning_speed") { row in
                row.title = "Scanning speed (Seconds)"
                row.value = self.scanningSpeed
                row.add(rule: RuleRequired())

                let ruleMax = RuleClosure<Double> { rowValue in
                    return (rowValue == nil || rowValue! < 0.1 || rowValue! > 100.0) ? ValidationError(msg: "Value must be between 0.1 and 100") : nil
                }

                row.add(rule: ruleMax)
                row.validationOptions = .validatesOnChange
            }
            .cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
        
            <<< DecimalRow("sticker_delay") { row in
                row.title = "Sticker Button Delay (Seconds)"
                row.value = self.stickerDelay
                row.add(rule: RuleRequired())
                
                let ruleMax = RuleClosure<Double> { rowValue in
                    return (rowValue == nil || rowValue! < 0.1 || rowValue! > 100.0) ? ValidationError(msg: "Value must be between 0.1 and 100") : nil
                }
                
                row.add(rule: ruleMax)
                row.validationOptions = .validatesOnChange
                }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
        }
    }

    // MARK: Init

    init(scanningSpeed: Double, stickerDelay: Double, completionHandler: ((Double, Double) -> Void)?) {
        self.scanningSpeed = scanningSpeed
        self.stickerDelay = stickerDelay
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func backPressed(_ sender: Any) {
        guard let scanningSpeedRow = self.form.rowBy(tag: "scanning_speed") as? DecimalRow,
            let scanningSpeed = scanningSpeedRow.value,
            scanningSpeedRow.isValid else {
            self.showAlert("Value must be between 0.1 and 100")
            return
        }
        
        guard let stickerDelayRow = self.form.rowBy(tag: "sticker_delay") as? DecimalRow,
            let stickerDelay = stickerDelayRow.value,
            stickerDelayRow.isValid else {
                self.showAlert("Value must be between 0.1 and 100")
                return
        }

        self.completionHandler?(scanningSpeed, stickerDelay)
    }

}
