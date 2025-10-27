// Created for Volumes by Andrew Lection on 8/15/25

import ARScene
import AudioSynthesizer
import Foundation

/// The primary coordinator for the Volumes app. Manages the following child coordinators:
/// - `ARSceneCoordinator`: Manages the AR experience including input from the AR session, and rendering 3D content.
/// - `AudioSynthCoordinator` Manages an audio synthesizer instance which is controlled by actions forwarded from the `AppCoordinator`
final class AppCoordinator: ObservableObject {
    struct NoteEventGenerator {
        struct NoteEvent {
            let pitch: Float
        }
        
        /// Provides the frequency in Hertz for notes in the C major scale across two octaves.
        let availablePitches: [Float] = [
            65.4,
            73.42,
            82.41,
            87.31,
            98.0,
            110.0,
            123.47,
            130.81,
            146.83,
            164.81,
            174.61,
            196.0,
            220.0,
            246.94
        ]
        
        func newEvent() -> NoteEvent {
            let pitch = availablePitches.randomElement() ?? 65.4
            return NoteEvent(pitch: pitch)
        }
    }

    // MARK: - Public Properties

    /// Manages the `ARView` including gestures and rendering 3D content in the scene.
    let arSceneCoordinator: ARSceneCoordinator
    
    // MARK: - Private Properties
    
    /// Manages an audio synthesizer.
    private let audioSynthesizer: AudioSynthesizerController
    
    /// Signal generators that drive the synth voices for the audio synthesizer.
    private let firstSignalGenerator = SignalGenerator()
    private let secondSignalGenerator = SignalGenerator()
    
    private let noteEventGenerator = NoteEventGenerator()
    
    // MARK: - Initialization

    public init() {
        self.arSceneCoordinator = ARSceneCoordinator()
        self.audioSynthesizer = AudioSynthesizerController(
            firstSignalGeneratorRenderBlock: firstSignalGenerator.renderBlock,
            secondSignalGeneratorRenderBlock: secondSignalGenerator.renderBlock
        )
        self.setup()
    }
    
    // MARK: - Private Methods
    
    private func setup() {
        setupARScene()
        setupAudioSynthesizer()
    }
    
    private func setupARScene() {
        arSceneCoordinator.onLongPressBegin = { [weak self] in
            guard let self else { return }
            setPitch(noteEventGenerator.newEvent().pitch)
            self.audioSynthesizer.fadeIn()
        }
        
        arSceneCoordinator.onLongPressEnd = { [weak self] in
            guard let self else { return }
            self.audioSynthesizer.fadeOut()
        }
    }
    
    private func setupAudioSynthesizer() {
        firstSignalGenerator.setWaveform(.triangle)
        secondSignalGenerator.setWaveform(.triangle)
        firstSignalGenerator.setAmplitude(-5.0)
        secondSignalGenerator.setAmplitude(-7.0)
        
        setPitch(noteEventGenerator.newEvent().pitch)
        
        audioSynthesizer.onDidSetSampleRate = { [weak self] sampleRate in
            guard let self else { return }
            self.firstSignalGenerator.setSampleRate(sampleRate)
            self.secondSignalGenerator.setSampleRate(sampleRate)
        }
        
        audioSynthesizer.start()
    }
    
    private func setPitch(_ pitch: Float) {
        let bassPitch: Float = pitch
        let treblePitch: Float = pitch * 1.3348 /// Perfect fourth above the bass pitch
        
        firstSignalGenerator.setFrequency(treblePitch)
        secondSignalGenerator.setFrequency(bassPitch)
    }
}
