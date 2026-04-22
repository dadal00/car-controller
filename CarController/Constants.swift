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
    static let voice        = CBUUID(string: "CCCC")
}

struct Wifi {
    static let udpIp = "192.168.2.3"
    static let udpPort: UInt16 = 1111
    
    
    struct Bonjour {
        static let id: String = randomString()
        static let type = "_carcontroller._udp"
        static let domain = "local"
        static let idLength = 6
        static let connections = 3
    }
}

// Target format: 16kHz, mono, Int16
struct Audio {
    static let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 48_000,
        channels: 1,
        interleaved: false
    )!
    
    static let bufferSize: UInt32 = 1024
    static let frameCapacity: UInt32 = 2048
    static let chunkByteSize = 1024
    
    struct Use {
        static let nothing: Int8 = -1
        static let command: Int8 = 0
        static let streaming: Int8 = 1
    }
}

struct VoiceCommands {
    static let speechType = "en-US"
    
    static let lightOn = "turn on"
    static let lightOff = "turn off"
    
    static let lightOnCommand: UInt8 = 0
    static let lightOffCommand: UInt8 = 1
    
    static let bonjourCommand: UInt8 = 2
}


