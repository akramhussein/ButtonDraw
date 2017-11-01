//
//  DrawViewController.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 14/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import Foundation
import Eureka

final class DrawViewController: FormViewController {

    private var connection: BluetoothConnection!
    private var mBot: MBot!
    private var device: BluetoothDevice!

    // MARK: Init

    init(connection: BluetoothConnection, device: BluetoothDevice) {
        self.connection = connection
        self.device = device
        self.mBot = MBot(connection: self.connection)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.isHidden = false

        form +++ Section("Co-ordinates")

            <<< IntRow("x") { row in
                row.placeholder = "100"
                row.value = 100
            }

            <<< IntRow("y") { row in
                row.placeholder = "100"
                row.value = 100
            }

            <<< ButtonRow("send") { row in
                row.title = "Send"
            }.cellSetup { cell, _ in
                cell.tintColor = .blue
            }.onCellSelection { _, _ in
                guard let xRow = self.form.rowBy(tag: "x") as? IntRow,
                    let x = xRow.value else {
                    return
                }

                guard let yRow = self.form.rowBy(tag: "y") as? IntRow,
                    let y = yRow.value else {
                    return
                }

//                self.mBot.sendXYDraw(x: x, y: y)
            }

            <<< ButtonRow("pen_up") { row in
                row.title = "Pen Up"
            }.cellSetup { cell, _ in
                cell.tintColor = .blue
            }.onCellSelection { _, _ in
                self.mBot.sendXYPen(.up)
            }

            <<< ButtonRow("pen_down") { row in
                row.title = "Pen Down"
            }.cellSetup { cell, _ in
                cell.tintColor = .blue
            }.onCellSelection { _, _ in
                self.mBot.sendXYPen(.down)
            }

            <<< ButtonRow("reset") { row in
                row.title = "Reset"
            }.cellSetup { cell, _ in
                cell.tintColor = .red
            }.onCellSelection { _, _ in
                self.mBot.sendXYReset()
            }
    }

}
