//
//  UdpClient.swift
//  CarController
//
//  Created by Dylan Adal on 4/16/26.
//

import Network
import SwiftUI

final class UDPClient {
    private let connection: NWConnection
    
    init(host: String, port: UInt16) {
        let endpoint = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!
        
        self.connection = NWConnection(host: endpoint, port: nwPort, using: .udp)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("UDP ready")
            case .failed(let error):
                print("UDP failed:", error)
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    func send(_ data: Data) {
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send error:", error)
            }
        })
    }
    
    func stop() {
        connection.cancel()
    }
}
