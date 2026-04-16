//
//  Constants.swift
//  CarController
//
//  Created by Dylan Adal on 2/23/26.
//

import CoreBluetooth
import AVFoundation

let isPeripheral = false

enum IDs {
    // uuids must be hex, 2 byte or 16 byte
    // example: F206765C-58A6-467B-8D8B-FCB9895E8FD0
    static let car          = CBUUID(string: "AAAA")
    static let control      = CBUUID(string: "BBBB")
}

struct Wifi {
    static let udpIp = "192.168.2.3"
    static let udpPort: UInt16 = 1111
}

// Target format: 16kHz, mono, Int16
struct Audio {
    static let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!
    
    static let bufferSize: UInt32 = 1024
    // roughly 20ms frames
    static let frameCapacity = AVAudioFrameCount(targetFormat.sampleRate * 0.02)
    static let chunkByteSize = 640
}


