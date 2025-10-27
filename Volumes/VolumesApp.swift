// Created for Volumes by Andrew Lection on 8/15/25

import SwiftUI

@main
struct VolumesApp: App {
    // MARK: - Private Properties

    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            AppContentView(appCoordinator: appCoordinator)
        }
    }
}
