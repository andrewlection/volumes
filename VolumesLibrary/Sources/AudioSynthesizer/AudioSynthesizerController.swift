// Created for VolumesLibrary by Andrew Lection on 8/15/25

import AVFoundation
import Foundation

/// Provides an interface for controlling a single synthesizer voice.
public final class AudioSynthesizerController {
    
    // MARK: - Public Properties
    
    public var firstSynthVoiceVolume: Float = 0.0 {
        didSet {
            firstSourceNode.volume = firstSynthVoiceVolume
        }
    }
    
    public var secondSynthVoiceVolume: Float = 0.0 {
        didSet {
            secondSourceNode.volume = secondSynthVoiceVolume
        }
    }
    
    public var onDidSetSampleRate: (Double) -> Void = { _ in }
    
    // MARK: - Private Properties
    
    private let audioEngine = AVAudioEngine()

    private var time: Float = 0
    private let sampleRate: Double
    private let deltaTime: Float
    
    private let firstSourceNode: AVAudioSourceNode
    private let secondSourceNode: AVAudioSourceNode
    
    private let firstDelayNode = AVAudioUnitDelay()
    private let firstReverbNode = AVAudioUnitReverb()
    
    private let secondDelayNode = AVAudioUnitDelay()
    private let secondReverbNode = AVAudioUnitReverb()
    
    private var fadeInDisplayLink: CADisplayLink?
    private var fadeOutDisplayLink: CADisplayLink?
    
    // MARK: - Initialization
    
    public init(
        firstSignalGeneratorRenderBlock: @escaping AVAudioSourceNodeRenderBlock,
        secondSignalGeneratorRenderBlock: @escaping AVAudioSourceNodeRenderBlock,
    ) {
        self.firstSourceNode = AVAudioSourceNode(renderBlock: firstSignalGeneratorRenderBlock)
        self.secondSourceNode = AVAudioSourceNode(renderBlock: secondSignalGeneratorRenderBlock)
        let mainMixer = self.audioEngine.mainMixerNode
        let outputNode = self.audioEngine.outputNode
        
        /// This is the format of the default audio settings for the device
        let format = outputNode.outputFormat(forBus: 0)
        
        /// Delta time is the duration of each sample
        self.sampleRate = format.sampleRate
        self.deltaTime = 1 / Float(sampleRate)
        
        /// The common format here is `AVAudioCommonFormat` which wraps Core Audio's `AudioStreamBasicDescription`
        /// (for example, `pcmFormatFloat32` or `pcmFormatFloat64`)
        /// When connecting nodes in an `AVAudioEngine` the format of the nodes must be compatiable.
        let inputFormat = AVAudioFormat(commonFormat: format.commonFormat, sampleRate: format.sampleRate, channels: 1, interleaved: format.isInterleaved)
        
        // Configure reverb
        firstReverbNode.loadFactoryPreset(.mediumHall)
        firstReverbNode.wetDryMix = 100
        
        secondReverbNode.loadFactoryPreset(.mediumHall)
        secondReverbNode.wetDryMix = 100
        
        // Configure delay
        firstDelayNode.delayTime = 0.5
        firstDelayNode.feedback = -25
        firstDelayNode.wetDryMix = 100
        
        secondDelayNode.delayTime = 0.5
        secondDelayNode.feedback = -25
        secondDelayNode.wetDryMix = 50
        
        firstSourceNode.volume = firstSynthVoiceVolume
        secondSourceNode.volume = secondSynthVoiceVolume

        /// Connect nodes to construct audio graph and initialize the audio engine
        audioEngine.attach(firstSourceNode)
        audioEngine.attach(secondSourceNode)
        audioEngine.attach(firstDelayNode)
        audioEngine.attach(firstReverbNode)
        audioEngine.attach(secondDelayNode)
        audioEngine.attach(secondReverbNode)
        audioEngine.connect(firstSourceNode, to: firstDelayNode, format: inputFormat)
        audioEngine.connect(firstDelayNode, to: firstReverbNode, format: inputFormat)
        audioEngine.connect(firstReverbNode, to: mainMixer, format: inputFormat)
        audioEngine.connect(secondSourceNode, to: secondDelayNode, format: inputFormat)
        audioEngine.connect(secondDelayNode, to: secondReverbNode, format: inputFormat)
        audioEngine.connect(secondReverbNode, to: mainMixer, format: inputFormat)
        audioEngine.connect(mainMixer, to: outputNode, format: nil)
        mainMixer.outputVolume = 0.5
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    public func start() {
        // Inform clients of sample rate that has been set
        onDidSetSampleRate(self.sampleRate)

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    public func fadeIn() {
        let displayLink = CADisplayLink(target: self, selector: #selector(fadeInAudio))
        displayLink.add(to: .current, forMode: .common)
        self.fadeInDisplayLink = displayLink
    }
    
    public func fadeOut() {
        let displayLink = CADisplayLink(target: self, selector: #selector(fadeOutAudio))
        displayLink.add(to: .current, forMode: .common)
        self.fadeOutDisplayLink = displayLink
    }
    
    public func stop() {
        audioEngine.stop()
    }
    
    // MARK: - Private Methods
    
    enum ParameterConstants {
        static let volumeFadeIncrement: Float = 0.01
    }
    
    @objc private func fadeInAudio() {
        if firstSourceNode.volume < 1 {
            firstSourceNode.volume += ParameterConstants.volumeFadeIncrement
        }
        
        if secondSourceNode.volume < 1 {
            secondSourceNode.volume += ParameterConstants.volumeFadeIncrement
        }
        
        if firstSourceNode.volume >= 1 && secondSourceNode.volume >= 1 {
            fadeInDisplayLink?.invalidate()
            fadeInDisplayLink = nil
        }
    }
    
    @objc private func fadeOutAudio() {
        if firstSourceNode.volume > 0 {
            firstSourceNode.volume -= ParameterConstants.volumeFadeIncrement
        }
        
        if secondSourceNode.volume > 0 {
            secondSourceNode.volume -= ParameterConstants.volumeFadeIncrement
        }
        
        if firstSourceNode.volume <= 0 && secondSourceNode.volume <= 0 {
            fadeOutDisplayLink?.invalidate()
            fadeOutDisplayLink = nil
        }
    }
}
