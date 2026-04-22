//
//  MicrophoneCapture.swift
//  CarController
//
//  Created by Dylan Adal on 4/16/26.
//

import AVFoundation
import Speech

class MicrophoneCapture: ObservableObject {
    private var bluetoothCentral: BluetoothCentral
    
    private let engine = AVAudioEngine()
    private let udpClient = UDPClient(host: Wifi.udpIp, port: Wifi.udpPort)
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var converter: AVAudioConverter!
//    private var convertedAudioBuffer = Data()
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var usingAudio = false
    
    init(bluetoothCentral: BluetoothCentral) {
//        let input = engine.inputNode
//        let inputFormat = input.inputFormat(forBus: 0)
        
//        converter = AVAudioConverter(from: inputFormat, to: Audio.targetFormat)
        self.bluetoothCentral = bluetoothCentral
        
//        try? engine.start()
    }
    
    private func restartCommand() {
        stop(option: Audio.Use.command)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                try self.start(option: Audio.Use.command)
            } catch {
                print("Restart failed:", error)
            }
        }
    }
    
    private func startSpeechRecognition(inputFormat: AVAudioFormat) {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                print("Heard: ", text)
                
                if text.contains(VoiceCommands.lightOn) {
                    bluetoothCentral.lightOn()
                    
                    restartCommand()
                }
                if text.contains(VoiceCommands.lightOff) {
                    bluetoothCentral.lightOff()
                    
                    restartCommand()
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
            }
        }
    }
    
    private func start(option: Int8) throws {
        guard !usingAudio else { return }
        usingAudio = true
        
        SFSpeechRecognizer.requestAuthorization { status in
            print(status)
        }
        
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        
        input.installTap(onBus: 0,
                         bufferSize: Audio.bufferSize,
                         format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
//            self.process(buffer: buffer, targetFormat: Audio.targetFormat)
            
            self.recognitionRequest?.append(buffer)
        }
        
        try engine.start()
        if option == Audio.Use.command {
            startSpeechRecognition(inputFormat: inputFormat)
        }
    }
    
    private func stopSpeechRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    
    private func stop(option: Int8) {
        guard usingAudio else { return }
        usingAudio = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

//        convertedAudioBuffer.removeAll()
        if option == Audio.Use.command {
            stopSpeechRecognition()
        }
    }
    
    func toggleStreaming(option: Int8) {
        do {
            if usingAudio {
                self.stop(option: option)
            } else {
                try self.start(option: option)
            }
        } catch {
            print("Streaming error: \(error)")
        }
    }
    
//    private func process(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
//        guard let converter = converter else { return }
//        
//        guard let convertedBuffer = AVAudioPCMBuffer(
//            pcmFormat: Audio.targetFormat,
//            frameCapacity: Audio.frameCapacity
//        ) else { return }
//        
//        var error: NSError?
//        
//        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
//            outStatus.pointee = .haveData
//            return buffer
//        }
//        
//        converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
//        
//        if let error = error {
//            print("Conversion error:", error)
//            return
//        }
//        
//        // Extract Int16 data
//        guard let channelData = convertedBuffer.int16ChannelData else { return }
//        
//        let frameLength = Int(convertedBuffer.frameLength)
//        let byteCount = frameLength * MemoryLayout<Int16>.size
//        
//        let pcmAudioBytes = Data(bytes: channelData[0], count: byteCount)
//        
//        sendPCMAudioBytes(pcmAudioBytes)
//    }
//    
//    private func sendPCMAudioBytes(_ data: Data) {
//        convertedAudioBuffer.append(data)
//        
//        while convertedAudioBuffer.count >= Audio.chunkByteSize {
//            let chunk = convertedAudioBuffer.prefix(Audio.chunkByteSize)
//            udpClient.send(chunk)
//            
//            convertedAudioBuffer.removeFirst(Audio.chunkByteSize)
//        }
//    }
}
