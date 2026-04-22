//
//  AudioPlayback.swift
//  CarController
//
//  Created by Dylan Adal on 4/21/26.
//

import AVFoundation

class AudioPlayback {
    private let audioEngineManager: AudioEngineManager
    let audioQueue: AudioBufferQueue
    private let playbackQueue = DispatchQueue(label: "audio.playback.queue")
    
    @Published var runningPlayback = false
    
    init(audioEngineManager: AudioEngineManager) {
        self.audioEngineManager = audioEngineManager
        self.audioQueue = AudioBufferQueue()
    }
    
    func startPlaybackLoop() {
        guard !audioEngineManager.usingAudio && !runningPlayback else {return}
        
        print("starting play")
        audioEngineManager.usingAudio = true
        runningPlayback = true
            
        try? audioEngineManager.engine.start()
        audioEngineManager.playerNode.play()
        
        playbackQueue.async { [weak self] in
                self?.playLoop()
            }
    }
    
    private func playLoop() {
        guard runningPlayback, audioEngineManager.usingAudio else { return }
        
        if let data = audioQueue.pop() {
            schedule(data)
        }
        
        playbackQueue.asyncAfter(deadline: .now() + 0.000) { [weak self] in
            self?.playLoop()
        }
    }
    
    func schedule(_ data: Data) {
        print(data.count)
        let frameCount = UInt32(data.count / MemoryLayout<Float>.size)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: Audio.targetFormat,
                                            frameCapacity: frameCount) else {
            return
        }

        buffer.frameLength = frameCount

        guard let dst = buffer.floatChannelData?[0] else {
            return
        }

        data.withUnsafeBytes { rawBuffer in
            let src = rawBuffer.bindMemory(to: Float.self)
            memcpy(dst, src.baseAddress!, Int(frameCount) * MemoryLayout<Float>.size)
        }
        audioEngineManager.playerNode.scheduleBuffer(buffer)
    }
    
    func stopPlayback() {
        guard audioEngineManager.usingAudio && runningPlayback else {return}
        self.audioEngineManager.usingAudio = false;
        runningPlayback = false;
        
        audioQueue.clear()
        
        audioEngineManager.playerNode.stop()
        audioEngineManager.playerNode.reset()
        audioEngineManager.engine.stop()
    }
    
    func togglePlayback() {
        if runningPlayback {
            self.stopPlayback()
        } else {
            self.startPlaybackLoop()
        }
    }
}
