//
//  EngineManager.swift
//  CarController
//
//  Created by Dylan Adal on 4/21/26.
//

import AVFoundation

class AudioEngineManager: ObservableObject {
    let engine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    
    @Published var usingAudio = false
    @Published var lastOption = Audio.Use.nothing

    init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: Audio.targetFormat)
    }
}
