// Created for VolumesLibrary by Andrew Lection on 8/15/25

import ARKit
import RealityKit

/// Models the actions emitted by the `ARSceneCoordinator`.
/// Hooks for these actions are provided in the form of closure callback properties,
/// for which the client of `ARScenceCoordinator` can define in order to handle a given action.
enum Action {
    case onLongPressBegin
    case onLongPressEnd
    case onLongPressDurationChange
}

/// Manages interactions with the `ARView` and provides callbacks to external clients pertaining to specific actions.
public final class ARSceneCoordinator: NSObject {
    // MARK: - Public Properties

    /// The primary view of the app which renders the AR experience
    weak var arView: ARView?
    
    /// Closure that runs if a long press on an entity in the scene begins.
    public var onLongPressBegin: (() -> Void)?
    /// Closure that runs if a long press on an entity in the scene ends.
    public var onLongPressEnd: (() -> Void)?
    /// Closure that runs if a long press on an entity in the scene changes.
    public var onLongPressDurationChange: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// Provides a constant time lookup to retrieve a `SphereEntity` instance corresponding to the given entity identifier..
    private var identifierToEntity: [String: SphereEntity] = [:]
    
    // MARK: - Public Methods
    
    /// Configures the gesture handlers for interaction with the `ARView`
    @MainActor func setupGestures() {
        // Add tap gesture, which is used to place new entities in the ARView
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        arView?.addGestureRecognizer(tap)
        
        // Add long gesture, which is used to drive an external action based on the start, stop,
        // and duration of the long press
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        arView?.addGestureRecognizer(longPress)
    }
    
    /// Handles a tap gesture, which adds a new entity at the location selection if an entity does not already exist at the selected location.
    @MainActor @objc func handleTap(_ recognizer: UITapGestureRecognizer? = nil) {
        guard let arView else { return }
        guard let twoDimensionalTouchPoint = recognizer?.location(in: arView) else { return }
        guard let raycastResult = makeRaycastQuery(fromPoint: twoDimensionalTouchPoint, arView: arView) else { return }
        
        // Only add a new entity if one does not already exist at the result of the raycast query
        guard arView.entity(at: twoDimensionalTouchPoint) == nil else { return }
        addEntityToScene(withRaycastResult: raycastResult, arView: arView)
    }
    
    @MainActor @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer? = nil) {
        guard let arView else { return }
        guard let gestureState = recognizer?.state else { return }
        guard let twoDimensionalTouchPoint = recognizer?.location(in: arView) else { return }
        
        guard let entity = arView.entity(at: twoDimensionalTouchPoint) else { return }
        guard let selectedSphere = identifierToEntity[entity.name] else { return }
        
        switch gestureState {
        case .began:
            selectedSphere.animateSelectBegin()
            onLongPressBegin?()
        case .changed:
            onLongPressDurationChange?()
        case .ended, .cancelled:
            selectedSphere.animateSelectEnd()
            onLongPressEnd?()
        default: break
        }
    }
    
    // MARK: - Private Methods
        
    /// Performs a raycast query in order to resolve a 3D location in the physical world from the selected 2D location on the screen.
    @MainActor private func makeRaycastQuery(fromPoint point: CGPoint, arView: ARView) -> ARRaycastResult? {
        guard let raycastQuery = arView.makeRaycastQuery(from: point, allowing: .estimatedPlane, alignment: .any)
        else { return nil }
        return arView.session.raycast(raycastQuery).first
    }
    
    /// Adds an entity attached to an anchor to the ARView's scene.
    @MainActor private func addEntityToScene(withRaycastResult result: ARRaycastResult, arView: ARView) {
        let sphere = createSphereEntity()
    
        /// Creates an anchor using the raycast result that detected a real-world surface.
        let anchorEntity = AnchorEntity(raycastResult: result)

        /// Attach the `ModelEntity` to the scene's anchor entity.
        anchorEntity.addChild(sphere.modelEntity)

        /// Adds the anchor to the scene which will reuslt in rendering the 3D model.
        arView.scene.addAnchor(anchorEntity)
        
        /// Store the sphere entity to look up later whenever this entity is selected.
        identifierToEntity[sphere.identifier] = sphere
        
        /// Begin animating the sphere entity
        sphere.initialAnimation()
    }
    
    /// Creates a new `SphereEntity` with a random tint color.
    @MainActor private func createSphereEntity() -> SphereEntity {
        let selectedTintColor = UIColor.tintColors.randomElement() ?? .blue
        return SphereEntity(tintColor: selectedTintColor)
    }
}

extension ARSceneCoordinator: ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {}
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {}
}
