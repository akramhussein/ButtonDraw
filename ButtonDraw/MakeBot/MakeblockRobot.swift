//
//  MakeblockRobot.swift
//  Makeblock
//
//  Created by Wang Yu on 6/6/16.
//  Copyright © 2016 Makeblock. All rights reserved.
//

import Foundation

/// The representation of the value returned from a mBot sensor
open class SensorValue {
    var numberValue: NSNumber?
    var stringValue: String?

    open var intValue: Int {
        if let intVal: Int = numberValue?.intValue {
            return intVal
        } else {
            return 0
        }
    }

    open var floatValue: Float {
        if let floatVal: Float = numberValue?.floatValue {
            return floatVal
        } else {
            return 0
        }
    }

    init(intValue: Int) {
        self.numberValue = intValue as NSNumber
    }

    init(floatValue: Float) {
        self.numberValue = floatValue as NSNumber
    }

    init(string: String) {
        self.stringValue = string
    }

}

/// The representation of a request sent to read a sensor value
open class ReadSensorRequest {
    let onRead: (SensorValue) -> Void
    var requestDate: Date

    init(callback: @escaping (SensorValue) -> Void) {
        self.onRead = callback
        self.requestDate = Date()
    }

    func isExpired() -> Bool {
        return false
    }

    func refresh() {
        self.requestDate = Date()
    }
}

/// The base class of a Makeblock Robot
open class MakeblockRobot {

    // makeblock protocol constants
    let prefixA: UInt8 = 0xFF
    let prefixB: UInt8 = 0x55
    let suffixA: UInt8 = 0x0D
    let suffixB: UInt8 = 0x0A

    /// an enum of electronic devices (sensors, motors, etc.)
    public enum DeviceID: UInt8 {
        case dcMotorMove = 0x05
        case dcMotor = 0x0A
        case rgbled = 0x08
        case buzzer = 0x22
        case ultrasonicSensor = 0x01
        case lightnessSensor = 0x03
        case lineFollowerSensor = 0x11
        case ledMatrix = 0x29
        case digital = 0x1E
        case pwm = 0x20
        case servo = 0xB
    }

    public enum PenPosition: String {
        case up, down
        
        public var next: PenPosition {
            return (self == .up) ? .down : .up
        }
    }

    public typealias SensorCallback = (SensorValue) -> Void

    var connection: Connection

    // the user of MakeblockRobot instances may attach one additional receive data callback.
    var onReceiveData: ((Data) -> Void)?
    var readSensorRequests: [UInt8: ReadSensorRequest] = [:]
    var receiveIndex: UInt8 = 0

    enum ReceiveStateMachineStates {
        case prefixA, prefixB, index, dataType, payload, suffixA, suffixB
    }
    enum ReceiveDataTypes: UInt8 {
        case singleByte = 1, float = 2, short = 3, string = 4, double = 5, long = 6
    }
    var receiveSMStatus: ReceiveStateMachineStates = .prefixA
    let expecetedPayloadCounts: [ReceiveDataTypes: UInt8] = [.singleByte: 1, .float: 4, .short: 2, .double: 4, .long: 4]
    var remainingPayloadLength: UInt8 = 0
    var receiveDataType: ReceiveDataTypes = .singleByte
    var receivedPayloads: [UInt8] = []

    // index is for identifying each "read sensor" type of request;
    // there's a bug in some version of mBot's firmware, so 0 is reserved for ultrasonic sensors;
    // 1 is reserved for writing
    // so reading starts at 2
    static let mininalReadingIndex: UInt8 = 2
    static let maximumReadingIndex: UInt8 = 254
    static let writingIndex: UInt8 = 1
    var currentIndex = mininalReadingIndex

    init(connection conn: Connection) {
        self.connection = conn
        self.connection.onReceive = self.onReceive
    }

    /// Makeblock's returning data format is like:
    ///     Prefix... | Index | Data Type           | Data Bytes ................ | Suffix
    ///     0xff  0x55  0x??    1: single byte          eg. 0x01                    0x0d  0x0a
    ///                         2: float (4 bytes)          0x03 0x01 0x01 0x0b
    ///                         3: short (2 bytes)          0x03 0x01
    ///                         4: String (2 bytes)     first byte is the string length
    ///                         5: double (4 bytes)          0x0d 0x0a 0x01 0x0b
    ///                         6: long (4 bytes)            unused
    ///
    /// A state machine is used to parse the returning data.
    /// for writing commands, will receive FF 55 0D 0A, and since 0x0a is not a data type,
    /// this will result in a parse failure and be ignored.
    func onReceive(_ data: Data) {
        var receivedBytes = [UInt8](repeating: 0, count: data.count)
        (data as NSData).getBytes(&receivedBytes, length: data.count)
        for byte in receivedBytes {
            switch self.receiveSMStatus {
            case .prefixA:
                if byte == self.prefixA {
                    self.receiveSMStatus = .prefixB
                }
            case .prefixB:
                if byte == self.prefixB {
                    self.receiveSMStatus = .index
                } else {
                    self.receiveSMStatus = .prefixA // parse failure, resetting
                }
            case .index:
                self.receiveIndex = byte
                self.receiveSMStatus = .dataType
            case .dataType:
                if let dataType = ReceiveDataTypes(rawValue: byte) {
                    self.receiveDataType = dataType
                    self.receiveSMStatus = .payload
                    self.receivedPayloads = [] // prepare to receive payloads
                    if dataType != .string {
                        // use a table to determine the payload length
                        self.remainingPayloadLength = self.expecetedPayloadCounts[dataType]!
                    } else {
                        // for string type, payload length is specified in next byte;
                        // but here init as 1, for 0 will result in a fall through
                        // of the payload reading phase
                        self.remainingPayloadLength = 1
                    }
                } else {
                    self.receiveSMStatus = .prefixA // parse failure, resetting
                }
            case .payload:
                // in String type, the first character is for length
                if self.remainingPayloadLength > 0 {
                    if self.receiveDataType == .string {
                        if self.receivedPayloads.count == 0 {
                            self.remainingPayloadLength = byte
                        } else {
                            self.receivedPayloads.append(byte)
                            self.remainingPayloadLength = self.remainingPayloadLength - 1
                        }
                    } else { // if data type is not String
                        self.receivedPayloads.append(byte)
                        self.remainingPayloadLength = self.remainingPayloadLength - 1
                    }
                }
                if self.remainingPayloadLength <= 0 {
                    self.receiveSMStatus = .suffixA
                }
            case .suffixA:
                if byte == self.suffixA {
                    self.receiveSMStatus = .suffixB
                } else {
                    self.receiveSMStatus = .prefixA
                }
            case .suffixB:
                // parse received bytes, according to their respected types
                if let request = readSensorRequests[receiveIndex] {
                    switch self.receiveDataType {
                    case .singleByte:
                        request.onRead(SensorValue(intValue: Int(self.receivedPayloads[0])))
                    case .float:
                        fallthrough
                    case .double:
                        // in Makeblock's MCU definition, Double is the same as Float;
                        // Then convert 4 bytes to a float value.
                        var f: Float = 0.0
                        memcpy(&f, receivedPayloads, 4)
                        request.onRead(SensorValue(floatValue: f))
                        receivedPayloads = []
                    case .short:
                        let value: Int = (Int(receivedPayloads[1]) << 8) | Int(receivedPayloads[0])
                        request.onRead(SensorValue(intValue: Int(value)))
                    case .long:
                        let first = (Int(receivedPayloads[3]) << 24) | (Int(receivedPayloads[2]) << 16)
                        let second = (Int(receivedPayloads[1]) << 8) | Int(receivedPayloads[0])
                        let value: Int = first | second
                        request.onRead(SensorValue(intValue: Int(value)))
                    case .string:
                        let resultString = NSString(bytes: receivedPayloads,
                                                    length: receivedPayloads.count,
                                                    encoding: String.Encoding.utf8.rawValue)! as String
                        request.onRead(SensorValue(string: resultString))
                    }
                    // the reading request is fulfilled. Remove from the pending request list.
                    self.readSensorRequests.removeValue(forKey: self.receiveIndex)
                }
                self.receiveSMStatus = .prefixA
            }
        }
        // if there are additional callbacks, run them.
        if let callback = onReceiveData {
            callback(data)
        }
    }

    /**
     Send a message through the Connection

     - parameter deviceID:     which device (motors, snesors etc.)
     - parameter arrayOfBytes: an UInt8 array of additional bytes to send
     - parameter callback:     if set, it will send a read sensor request and callback when it receives a sensor value

     - returns: the index of the sent package. Often used in unit tests.
     */
    func sendMessage(_ deviceID: DeviceID, arrayOfBytes: [UInt8], callback: ((SensorValue) -> Void)? = nil) -> UInt8 {
        let metaDataLength: UInt8 = 3
        let messageLength: UInt8 = metaDataLength + UInt8(arrayOfBytes.count)
        let readWriteByte: UInt8 = callback != nil ? 1 : 2
        var index = MakeblockRobot.writingIndex
        if let cb = callback {
            index = currentIndex
            self.currentIndex = self.currentIndex + 1
            if self.currentIndex > MakeblockRobot.maximumReadingIndex {
                self.currentIndex = MakeblockRobot.mininalReadingIndex
            }

            // register callback to read sensor callback list
            self.readSensorRequests[index] = ReadSensorRequest(callback: cb)
        }
        var finishedBytes: [UInt8] = [prefixA, prefixB, messageLength, index, readWriteByte, deviceID.rawValue]
        finishedBytes.append(contentsOf: arrayOfBytes)
        connection.send(Data(bytes: UnsafePointer<UInt8>(finishedBytes), count: finishedBytes.count))
        return index
    }

    /**
     Send a draw message through the Connection

     - parameter x:             X co-ordinate
     - parameter y:             Y co-ordinate
     */
    func sendXYDraw(x: Double, y: Double) {
        
        print("Drawing to x: \(x) y: \(y)")
        let cmd: [UInt8] = Array("G1 X\(x) Y\(y)\n".utf8)

        connection.send(Data(bytes: UnsafePointer<UInt8>(cmd), count: cmd.count))
    }

    /**
     Send a draw message through the Connection

     - parameter position: Pen Position
     */
    func sendXYPen(_ position: PenPosition) {
        let pos = (position == .up) ? 0 : 90

        let cmd: [UInt8] = Array("M1 \(pos)\n".utf8)

        connection.send(Data(bytes: UnsafePointer<UInt8>(cmd), count: cmd.count))
    }

    /**
     Send a draw message through the Connection

     - parameter position: Pen Position
     */
    func sendXYReset() {
        let cmd: [UInt8] = Array("G28\n".utf8)

        connection.send(Data(bytes: UnsafePointer<UInt8>(cmd), count: cmd.count))
    }

}
