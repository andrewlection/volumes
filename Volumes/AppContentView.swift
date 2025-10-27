// Created for VolumesLibrary by Andrew Lection on 8/15/25

import ARScene
import SwiftUI

/// The root view for the Volumes app, which provides an AR experience
/// for creating a musical sequence by adding and modifying orbs in AR space.
struct AppContentView: View {
    // MARK: - Private Properties
    
    /// The primary coordinator for the app.
    /// - Vends the `ARSceneCoordinator` and the `SynthesizerCoordinator`
    /// - Receives updates from the AR session and transforms these updates to actions to call on the synthesizer.
    private let appCoordinator: AppCoordinator
    
    /// Manages the primary view of the app.
    private var arSceneCoordinator: ARSceneCoordinator {
        appCoordinator.arSceneCoordinator
    }
    
    var body: some View {
        VStack {
            ARSceneView(coordinator: arSceneCoordinator)
                .ignoresSafeArea(edges: .all)
        }
    }
    
    // MARK: - Initialization
    
    public init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }
}

#Preview {
    AppContentView(appCoordinator: AppCoordinator())
}
