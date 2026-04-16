struct ControlState: Equatable {
    let magnitude: UInt8
    let angle: UInt16
}

import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetoothCentral: BluetoothCentral
    
    @State private var magnitude: UInt8 = 0
    @State private var angle: UInt16 = 0
    
    var udpClient: UDPClient
    
    var body: some View {
        VStack {
            JoystickView(magnitude: $magnitude, angle: $angle).frame(maxWidth: .infinity)
            
            Text(bluetoothCentral.carPeripheral != nil ? "Connected" : "Disconnected")
                .foregroundColor(.white)
                .padding(8)
                .background(bluetoothCentral.carPeripheral != nil ? Color.green : Color.red)
                .cornerRadius(8)
            Button("Send UDP") {
                var data = Data()
                data.append(magnitude)
                
                // UInt16 → 2 bytes (big endian or little depending on your server)
                data.append(UInt8(angle >> 8))      // high byte
                data.append(UInt8(angle & 0xFF))    // low byte
                
                udpClient.send(data)
            }
        }
        .padding()
        .onChange(of: ControlState(magnitude: magnitude, angle: angle)) { controlState in
            print("Control changed: \(controlState.magnitude), \(controlState.angle)")
            bluetoothCentral.updateCar(magnitude: controlState.magnitude, angle: controlState.angle)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            bluetoothCentral: BluetoothCentral(),
            udpClient: UDPClient(host: udpIP, port: udpPort)
        )    }
}
