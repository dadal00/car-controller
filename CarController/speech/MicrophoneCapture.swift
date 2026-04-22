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
    
    private let audioEngineManager: AudioEngineManager
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: VoiceCommands.speechType))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var converter: AVAudioConverter!
    private var convertedAudioBuffer: AVAudioPCMBuffer?
    private var recognitionTask: SFSpeechRecognitionTask?
    
//     let audioPlayback: AudioPlayback
    
    
    init(bluetoothCentral: BluetoothCentral, audioEngineManager: AudioEngineManager) {
        self.audioEngineManager = audioEngineManager
        
        let input = audioEngineManager.engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        
        converter = AVAudioConverter(from: inputFormat, to: Audio.targetFormat)
        convertedAudioBuffer = AVAudioPCMBuffer(
            pcmFormat: Audio.targetFormat,
            frameCapacity: Audio.frameCapacity
        )
        self.bluetoothCentral = bluetoothCentral
        
//        self.audioPlayback = AudioPlayback(audioEngineManager: audioEngineManager)
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
        guard !audioEngineManager.usingAudio else { return }
        audioEngineManager.usingAudio = true
        
        let input = audioEngineManager.engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        
        input.installTap(onBus: 0,
                         bufferSize: Audio.bufferSize,
                         format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            
            if option == Audio.Use.streaming {
                self.convertAndSend(buffer: buffer, converter: converter, targetFormat: Audio.targetFormat)
            }
            
            if option == Audio.Use.command {
                self.recognitionRequest?.append(buffer)
            }
        }
        
        try audioEngineManager.engine.start()
        if option == Audio.Use.command {
            SFSpeechRecognizer.requestAuthorization { status in
                print(status)
            }
            
            startSpeechRecognition(inputFormat: inputFormat)
        }
        
        audioEngineManager.lastOption = option
    }
    
    private func stopSpeechRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    
    private func stop(option: Int8) {
        guard audioEngineManager.usingAudio && audioEngineManager.lastOption == option else { return }
        audioEngineManager.usingAudio = false

        audioEngineManager.engine.inputNode.removeTap(onBus: 0)
        audioEngineManager.engine.stop()
        
        if option == Audio.Use.command {
            stopSpeechRecognition()
        }
        
        audioEngineManager.lastOption = Audio.Use.nothing
    }
    
    func toggleAudio(option: Int8) {
        do {
            if audioEngineManager.usingAudio {
                self.stop(option: option)
            } else {
                try self.start(option: option)
            }
        } catch {
            print("Streaming error: \(error)")
        }
    }
    
    private func convertAndSend(
            buffer: AVAudioPCMBuffer,
            converter: AVAudioConverter,
            targetFormat: AVAudioFormat
    ) {
        guard let outputBuffer = convertedAudioBuffer, convertedAudioBuffer != nil else {return}
        
        var error: NSError?

        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            print("Conversion error:", error)
            return
        }

        guard let channelData = outputBuffer.floatChannelData else { return }

        let frameLength = Int(outputBuffer.frameLength)
        let byteCount = frameLength * MemoryLayout<Float32>.size

        let pcmAudioBytes = Data(bytes: channelData[0], count: byteCount)

        sendPCMAudioBytes(pcmAudioBytes)
    }
    
    private func sendPCMAudioBytes(_ data: Data) {
        guard bluetoothCentral.udpClient != nil else {return}
        
        var offset = 0

        while offset < data.count {
            let size = min(Audio.chunkByteSize, data.count - offset)
            let chunk = data.subdata(in: offset..<offset + size)

//            self.audioPlayback.audioQueue.push(chunk)
            bluetoothCentral.udpClient!.send(chunk)

            offset += size
        }
        
//        print("Sent!")
    }
}
