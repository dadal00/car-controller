//
//  CarControllerApp.swift
//  CarController
//
//  Created by Dylan Adal on 2/18/26.
//

import SwiftUI

@main
struct CarControllerApp: App {
    // state object is used when we want to track changes and show them in the visuals
    @StateObject var bluetoothCentral: BluetoothCentral
    @StateObject var microphoneCapture: MicrophoneCapture
    @StateObject var audioEngineManager: AudioEngineManager
    @StateObject var udpServer: UDPServer
    
    var bluetoothPeripheral = BluetoothPeripheral()
    
    
    init() {
        let bluetoothCentral = BluetoothCentral()
        let audioEngineManager = AudioEngineManager()
        
        _bluetoothCentral = StateObject(wrappedValue: bluetoothCentral)
        _audioEngineManager = StateObject(wrappedValue: audioEngineManager)
        _microphoneCapture = StateObject(
            wrappedValue: MicrophoneCapture(bluetoothCentral: bluetoothCentral, audioEngineManager: audioEngineManager)
        )
        _udpServer = StateObject(wrappedValue: UDPServer(bluetoothCentral: bluetoothCentral, audioPlayback: AudioPlayback(audioEngineManager: audioEngineManager)))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(bluetoothCentral: bluetoothCentral, microphoneCapture: microphoneCapture, audioEngineManager: audioEngineManager, udpServer: udpServer)
        }
    }
}
