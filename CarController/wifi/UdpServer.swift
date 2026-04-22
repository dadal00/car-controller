//
//  UdpServer.swift
//  CarController
//
//  Created by Dylan Adal on 4/21/26.
//

import Network
import SwiftUI

final class UDPServer: ObservableObject {
    private var listener: NWListener?
    private var bluetoothCentral: BluetoothCentral
    private var audioPlayback: AudioPlayback
    
    private var connections: [NWConnection] = []
    
    @Published var isReceiving = false
    
    init(bluetoothCentral: BluetoothCentral, audioPlayback: AudioPlayback) {
        self.bluetoothCentral = bluetoothCentral
        self.audioPlayback = audioPlayback
    }

    private func startReceiving(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            if let data = data {
                self?.audioPlayback.audioQueue.push(data)
            }

            if error == nil {
                self?.startReceiving(on: connection)
            }
        }
    }
    
    func start() {
        guard !isReceiving else {return}
        isReceiving = true
        self.audioPlayback.startPlaybackLoop()
        
        let port = NWEndpoint.Port(rawValue: Wifi.udpPort)!
        
        let listener = try! NWListener(using: .udp, on: port)
        self.listener = listener
        
        listener.service = NWListener.Service(
            name: Wifi.Bonjour.id,
            type: Wifi.Bonjour.type,
            domain: Wifi.Bonjour.domain
        )

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            self.connections.append(connection)
            
            
            connection.start(queue: .main)
            
            print("New receiving connection")
            self.startReceiving(on: connection)
        }
        
        listener.stateUpdateHandler = { state in
            print("Listener state:", state)
        }
                
        listener.start(queue: .main)
        
        print("Receiving started")
    }

    func stop() {
        guard isReceiving else {return}
        isReceiving = false
        
        listener?.cancel()
        listener = nil

        for connection in connections {
            connection.cancel()
        }

        connections.removeAll()
        self.audioPlayback.stopPlayback()

        print("Receiving stopped")
    }
    
    func toggleReceiving() {
        if self.isReceiving {
            self.stop()
        } else {
            self.start()
        }
    }
}
