struct ControlState: Equatable {
    let magnitude: UInt8
    let angle: UInt16
}

import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetoothCentral: BluetoothCentral
    @ObservedObject var microphoneCapture: MicrophoneCapture
    @ObservedObject var audioEngineManager: AudioEngineManager
    @ObservedObject var udpServer: UDPServer
    
    @State private var magnitude: UInt8 = 0
    @State private var angle: UInt16 = 0
    
    var body: some View {
        VStack {
            Button(action: {
                                udpServer.toggleReceiving()
//                microphoneCapture.audioPlayback.togglePlayback()
            }) {
                Text(udpServer.isReceiving ? "Receiving Audio" : "Not Receiving Audio")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        udpServer.isReceiving ? Color.green : Color.red
//                        microphoneCapture.audioPlayback.runningPlayback ? Color.green : Color.red
                    )
                    .cornerRadius(8)
            }.padding(.vertical, 40)
            
            Button(action: {
                microphoneCapture.toggleAudio(option: Audio.Use.streaming)
            }) {
                Text(audioEngineManager.lastOption == Audio.Use.streaming ? "Streaming Audio" : "Not Streaming Audio")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(audioEngineManager.lastOption == Audio.Use.streaming ? Color.green : Color.red)
                    .cornerRadius(8)
            }.padding(.vertical, 40)
            
            Button(action: {
                microphoneCapture.toggleAudio(option: Audio.Use.command)
            }) {
                Text(audioEngineManager.lastOption == Audio.Use.command ? "Running Commands" : "Not Running Commands")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(audioEngineManager.lastOption == Audio.Use.command ? Color.green : Color.red)
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
        let bluetoothCentral = BluetoothCentral()
        let audioEngineManager = AudioEngineManager()
        let udpServer = UDPServer(bluetoothCentral: bluetoothCentral, audioPlayback: AudioPlayback(audioEngineManager: audioEngineManager))
        
        let microphoneCapture = MicrophoneCapture(
            bluetoothCentral: bluetoothCentral,
            audioEngineManager: audioEngineManager
        )
        
        return ContentView(
            bluetoothCentral: bluetoothCentral,
            microphoneCapture: microphoneCapture,
            audioEngineManager: audioEngineManager,
            udpServer: udpServer
        )
    }
}
