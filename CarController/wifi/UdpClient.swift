//
//  UdpClient.swift
//  CarController
//
//  Created by Dylan Adal on 4/16/26.
//

import Network
import SwiftUI

final class UDPClient {
    private var connections: [String: NWConnection] = [:]
    private var browser: NWBrowser
    private var filtered: [String]?
    
    init(targetIdsBytes: [UInt8]) {
        print("Starting client!")
        
        self.browser = NWBrowser(
            for: .bonjour(type: Wifi.Bonjour.type, domain: Wifi.Bonjour.domain),
            using: .udp
        )
        
        guard let convertedTarget = String(bytes: targetIdsBytes, encoding: .utf8) else {
            return
        }
        
        let chunks = stride(from: 0, to: convertedTarget.count, by: Wifi.Bonjour.idLength).map { start -> String in
            let startIndex = convertedTarget.index(convertedTarget.startIndex, offsetBy: start)
            let endIndex = convertedTarget.index(startIndex, offsetBy: Wifi.Bonjour.idLength, limitedBy: convertedTarget.endIndex) ?? convertedTarget.endIndex
            return String(convertedTarget[startIndex..<endIndex])
        }
        
        self.filtered = chunks.filter { $0 != Wifi.Bonjour.id }
        
        self.browser.browseResultsChangedHandler = { results, changes in
            for result in results {
                if self.connections.count >= 3 {
                    print("Max connections reached")
                    break
                }
                
                switch result.endpoint {
                case .service(let name, let type, let domain, _):
                    print("Found service:", name, type, domain)
                    
                    if let filtered = self.filtered,
                       filtered.count > 0,
                       filtered.contains(name) {
                        let newConnection = NWConnection(to: result.endpoint, using: .udp)
                            
                        newConnection.stateUpdateHandler = { state in
                                switch state {
                                case .ready:
                                    print("Connected via Bonjour")
                                    self.connections[name] = newConnection
                                case .failed(let error):
                                    print("Connection failed:", error)
                                default:
                                    break
                                }
                            }
                            
                        newConnection.start(queue: .global())
                    }
                    
                default:
                    break
                }
            }
        }

        self.browser.start(queue: .main)
    }
    
    func send(_ data: Data) {
        for (_, connection) in connections {
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Send error:", error)
                }
            })
        }
    }
    
    func stop() {
        for (_, connection) in connections {
            connection.cancel()
        }
        connections.removeAll()
        
        browser.cancel()
    }
}
