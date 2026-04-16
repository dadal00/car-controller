//
//  MicrophoneCapture.swift
//  CarController
//
//  Created by Dylan Adal on 4/16/26.
//

import AVFoundation

class MicrophoneCapture: ObservableObject {
    private let engine = AVAudioEngine()
    private let udpClient = UDPClient(host: Wifi.udpIp, port: Wifi.udpPort)
    
    private var converter: AVAudioConverter!
    private var convertedAudioBuffer = Data()
    
    @Published var isStreaming = false
    
    init() {
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        
        converter = AVAudioConverter(from: inputFormat, to: Audio.targetFormat)
        
        try? engine.start()
    }
    
    private func start() throws {
        guard !isStreaming else { return }
        isStreaming = true
        
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        
        input.installTap(onBus: 0,
                         bufferSize: Audio.bufferSize,
                         format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.process(buffer: buffer, targetFormat: Audio.targetFormat)
        }
        
        try engine.start()
    }
    
    
    private func stop() {
        guard isStreaming else { return }
        isStreaming = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        convertedAudioBuffer.removeAll()
    }
    
    func toggleStreaming() {
        do {
            if isStreaming {
                self.stop()
            } else {
                try self.start()
            }
        } catch {
            print("Streaming error: \(error)")
        }
    }
    
    private func process(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let converter = converter else { return }
        
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: Audio.targetFormat,
            frameCapacity: Audio.frameCapacity
        ) else { return }
        
        var error: NSError?
        
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            print("Conversion error:", error)
            return
        }
        
        // Extract Int16 data
        guard let channelData = convertedBuffer.int16ChannelData else { return }
        
        let frameLength = Int(convertedBuffer.frameLength)
        let byteCount = frameLength * MemoryLayout<Int16>.size
        
        let pcmAudioBytes = Data(bytes: channelData[0], count: byteCount)
        
        sendPCMAudioBytes(pcmAudioBytes)
    }
    
    private func sendPCMAudioBytes(_ data: Data) {
        convertedAudioBuffer.append(data)
        
        while convertedAudioBuffer.count >= Audio.chunkByteSize {
            let chunk = convertedAudioBuffer.prefix(Audio.chunkByteSize)
            udpClient.send(chunk)
            
            convertedAudioBuffer.removeFirst(Audio.chunkByteSize)
        }
    }
}
