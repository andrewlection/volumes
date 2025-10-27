# volumes: a AR Music Synthesizer by Andrew Lection

https://github.com/user-attachments/assets/02b00bfb-c4ee-43fe-a847-18a548841fe7

## Intro
volumes is an instrument for creating ambient music while spatially interacting with 3D orbs rendered in the physical world
via an augmented reality experience.

## Functionality

To get started, direct the device's camera around the space (on onboarding overlay is displayed when applicable).

Tapping on the screen will then anchor a new orb entity relative to a detected horizontal or vertical plane.

Long pressing on any orb will play a single pitch via a 2 oscillator triangle wave synth voice. 
When a given orb is selected, the orb will freeze in place and the orb's light will increase while playing the note.

## Architecture

The project uses Swift Packages to modularize each feature, with the two features being the ARScene and the AudioSynthesizer.

The VolumesLibrary Swift package contains both of these feature targets, which the VolumesApp target imports as necessary:

VolumesLibrary:
- Sources/ARScene
- Sources/AudioSynthesizer

The VolumesApp target implements an AppCoordinator, which orchestrates the data flow of interactions with the ARScene, and then
maps these interactions to actions called on the AudioSynthesizer.

Additionally, the VolumesApp target contains a directory `AudioSignalGenerator` which implements a signal generating kernel in C++. 
This is adapted from Apple's sample code here: https://developer.apple.com/documentation/avfaudio/building-a-signal-generator
The signal generating kernel provides the sample values for the triangle waveform to the AVAudioSourceNode's rendering block.

        ----------------                             -------------------------- 
        |   VolumesApp |                             |     AppCoordinator     |  
        |______________|                             |________________________|  
               |                                        |                   | 1. the AppCoordinator receives events from the ARSceneCoordinator
               V                                        |                   | 2. the AppCoordinator then transforms these events into actions called
     ----------------------                             |                   | on the AudioSynthesizerController.
     |   AppContentView   |                             |                   |
     |____________________|                             |                   |
               |                                        |                   |
               V                                        V                   V
     ----------------------  Gestures   -----------------------         ------------------------------            
     |   ARSceneView      | ----------> | ARSceneCoordinator  |         | AudioSynthesizerController |
     |____________________|             |_____________________|         |____________________________|
               |                                                                     |
               V                                                                     V
     ----------------------                                                ----------------------         
     | ARView(RealityKit) |                                                |   AVAudioEngine    |
     |____________________|                                                |____________________|


With this modularization, the ARScene feature and the AudioSynthesizer feature remain decoupled, which promotes clean, testable API boundaries.
Additionally, other components could be added to the app by interfacing with the AppCoordinator. 
For example, the events from the ARScene could then drive a game engine while the game engine remains decoupled from the ARScene feature.

