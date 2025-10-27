// Created for VolumesLibrary by Andrew Lection on 8/15/25

import ARKit
import RealityKit
import SwiftUI

/// Initializes the ARKit tracking configuration and manages rendering objects in AR space using RealityKit.
public struct ARSceneView: UIViewRepresentable {
    
    // MARK: - Private Properties
    
    private let arSceneCoordinator: ARSceneCoordinator
    
    // MARK: - UIViewRepresentable

    public func makeUIView(context: Context) -> ARView {
        // RealityKit provides the ARView to render 3D content.
        let arView = ARView(frame: .zero)
        
        arView.session.delegate = arSceneCoordinator
        arSceneCoordinator.arView = arView
        
        // Set up the tracking configuration for the AR session.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        // Run the session with the specified configuration
        arView.session.run(configuration)
        
        // Customize gestures for interacting with AR scene
        arSceneCoordinator.setupGestures()
        
        // Add coaching overlay for onboarding
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)
        return arView
    }
    
    public func updateUIView(_ uiView: ARView, context: Context) {}
    
    // MARK: - Initialization
    
    public init(coordinator: ARSceneCoordinator) {
        self.arSceneCoordinator = coordinator
    }
}
