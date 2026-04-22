//
//  AudioQueue.swift
//  CarController
//
//  Created by Dylan Adal on 4/22/26.
//
import SwiftUI

final class AudioBufferQueue {
    private var buffers: [Data] = []
    private let lock = NSLock()
    
    func push(_ data: Data) {
        lock.lock()
        buffers.append(data)
        lock.unlock()
    }
    
    func pop() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return buffers.isEmpty ? nil : buffers.removeFirst()
    }
    
    func clear() {
        lock.lock()
        buffers.removeAll()
        lock.unlock()
    }
}
