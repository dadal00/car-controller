//
//  Constants.swift
//  CarController
//
//  Created by Dylan Adal on 2/23/26.
//

import CoreBluetooth

let isPeripheral = false

enum IDs {
    // uuids must be hex, 2 byte or 16 byte
    // example: F206765C-58A6-467B-8D8B-FCB9895E8FD0
    static let car          = CBUUID(string: "AAAA")
    static let control      = CBUUID(string: "BBBB")
}

let udpIP = "192.168.2.3"
let udpPort: UInt16 = 1111
