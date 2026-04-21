struct ControlState: Equatable {
    let magnitude: UInt8
    let angle: UInt16
}

import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetoothCentral: BluetoothCentral
    @ObservedObject var microphoneCapture: MicrophoneCapture
    
    @State private var magnitude: UInt8 = 0
    @State private var angle: UInt16 = 0
    
    var body: some View {
        VStack {
            Button(action: {
                microphoneCapture.toggleStreaming()
            }) {
                Text(microphoneCapture.isStreaming ? "Speaking" : "Not Speaking")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(microphoneCapture.isStreaming ? Color.green : Color.red)
                    .cornerRadius(8)
            }.padding(.vertical, 40)
            
            JoystickView(magnitude: $magnitude, angle: $angle).frame(maxWidth: .infinity)
            
            Text(bluetoothCentral.carPeripheral != nil ? "Connected" : "Disconnected")
                .foregroundColor(.white)
                .padding(8)
                .background(bluetoothCentral.carPeripheral != nil ? Color.green : Color.red)
                .cornerRadius(8)
        }
        .padding()
        .onChange(of: ControlState(magnitude: magnitude, angle: angle)) { controlState in
            //            print("Control changed: \(controlState.magnitude), \(controlState.angle)")
            bluetoothCentral.updateCar(magnitude: controlState.magnitude, angle: controlState.angle)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            bluetoothCentral: BluetoothCentral(),
            microphoneCapture: MicrophoneCapture(bluetoothCentral: BluetoothCentral())
        )    }
}
