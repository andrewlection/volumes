// Created for VolumesLibrary by Andrew Lection on 8/15/25

@preconcurrency import RealityKit
import UIKit

/// Encapsulates a single sphere `ModelEntity` and provides an interface for animating the model entity.
@MainActor final class SphereEntity {
    private enum GeometryConstants {
        static let sphereRadius: Float = 0.1
    }
    
    private enum MaterialConstants {
        static let opacity:  PhysicallyBasedMaterial.Opacity = 0.8
    }
    
    private enum AnimationConstants {
        static let emissiveIntensityIncrement: Float = 0.1
        static let minimumEmissiveIntensity: Float = 1.0
        static let maximumEmissiveIntensity: Float = 10.0
        static let maximumYDelta: Float = 0.1
        static let refreshInterval: TimeInterval = 1.0 / 60.0
        static let yPositionIncrement: Float = 0.001
    }

    // MARK: - Public  Properties
    
    let modelEntity: ModelEntity
    
    var identifier: String {
        modelEntity.name
    }

    // MARK: - Private Properties

    private var increasingEmissiveIntensity: Bool = true
    private var increasingYPosition: Bool = true
    private var yPositionDelta: Float = 0.0
    
    private var initialAnimationDisplayLink: CADisplayLink?
    private var positionAnimationDisplayLink: CADisplayLink?
    
    private var animateSelectBeginDisplayLink: CADisplayLink?
    private var animateSelectEndDisplayLink: CADisplayLink?
    
    private var isSelected: Bool = false
    
    // MARK: - Initialization
    
    init(tintColor: UIColor) {
        /// First, create the spherical geometry
        let sphereResource = MeshResource.generateSphere(radius: GeometryConstants.sphereRadius)
        
        /// Then, create a material used to render the visual properties of the sphere
        var sphereMaterial = PhysicallyBasedMaterial()
        sphereMaterial.baseColor = .init(tint: tintColor)
        sphereMaterial.blending = .transparent(opacity: MaterialConstants.opacity)
        sphereMaterial.metallic = 0.0
        sphereMaterial.roughness = 0.2
        sphereMaterial.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: tintColor)
        sphereMaterial.emissiveIntensity = AnimationConstants.minimumEmissiveIntensity
        
        /// Finally, combine the generated mesh and material to create a `ModelEntity`
        let modelEntity = ModelEntity(mesh: sphereResource, materials: [sphereMaterial])
        modelEntity.name = UUID().uuidString
        
        /// Add CollisionComponent for gesture recognition
        modelEntity.generateCollisionShapes(recursive: true)
        self.modelEntity = modelEntity
    }
    
    // MARK: - Public Methods
    
    func initialAnimation() {
        let displayLink = CADisplayLink(target: self, selector: #selector(animateMaterial))
        displayLink.add(to: .current, forMode: .common)
        self.initialAnimationDisplayLink = displayLink
        
        let positionDisplayLink = CADisplayLink(target: self, selector: #selector(animatePosition))
        positionDisplayLink.add(to: .current, forMode: .common)
        self.positionAnimationDisplayLink = positionDisplayLink
    }
    
    func animateSelectBegin() {
        // Invalidate the animation for when a selection ends, in case that animation is still in-progress
        self.animateSelectEndDisplayLink?.invalidate()
        self.animateSelectEndDisplayLink = nil

        self.isSelected = true
        let displayLink = CADisplayLink(target: self, selector: #selector(animateMaterialToMaximumIntensity))
        displayLink.add(to: .current, forMode: .common)
        self.animateSelectBeginDisplayLink = displayLink
    }
    
    func animateSelectEnd() {
        // Invalidate the animation for when a selection begins, in case that animation is still in-progress
        self.animateSelectBeginDisplayLink?.invalidate()
        self.animateSelectBeginDisplayLink = nil
        
        self.isSelected = false
        let displayLink = CADisplayLink(target: self, selector: #selector(animateMaterialToMinimumIntensity))
        displayLink.add(to: .current, forMode: .common)
        self.animateSelectEndDisplayLink = displayLink
    }
    
    // MARK: - Private Methods
    
    /// Animates the `emissiveItensity` of the entity's physically based material.
    @objc private func animateMaterial() {
        guard var sphereMaterial = modelEntity.model?.materials.first as? PhysicallyBasedMaterial else { return }
        if self.increasingEmissiveIntensity {
            sphereMaterial.emissiveIntensity += AnimationConstants.emissiveIntensityIncrement
            if sphereMaterial.emissiveIntensity >= AnimationConstants.maximumEmissiveIntensity {
                self.increasingEmissiveIntensity = false
            }
    
            self.modelEntity.model?.materials[0] = sphereMaterial
        } else {
            sphereMaterial.emissiveIntensity -= AnimationConstants.emissiveIntensityIncrement
            if sphereMaterial.emissiveIntensity <= AnimationConstants.minimumEmissiveIntensity {
                if let initialAnimationDisplayLink = self.initialAnimationDisplayLink {
                    initialAnimationDisplayLink.invalidate()
                    self.initialAnimationDisplayLink = nil
                    return
                } else {
                    self.increasingEmissiveIntensity = true
                }
            }
            
            self.modelEntity.model?.materials[0] = sphereMaterial
        }
    }
    
    @objc private func animateMaterialToMaximumIntensity() {
        guard var sphereMaterial = modelEntity.model?.materials.first as? PhysicallyBasedMaterial else { return }
        if sphereMaterial.emissiveIntensity < AnimationConstants.maximumEmissiveIntensity {
            sphereMaterial.emissiveIntensity += AnimationConstants.emissiveIntensityIncrement
        } else {
            self.animateSelectBeginDisplayLink?.invalidate()
            self.animateSelectBeginDisplayLink = nil
        }

        self.modelEntity.model?.materials[0] = sphereMaterial
    }
    
    @objc private func animateMaterialToMinimumIntensity() {
        guard var sphereMaterial = modelEntity.model?.materials.first as? PhysicallyBasedMaterial else { return }
        if sphereMaterial.emissiveIntensity > AnimationConstants.minimumEmissiveIntensity {
            sphereMaterial.emissiveIntensity -= AnimationConstants.emissiveIntensityIncrement
        } else {
            self.animateSelectEndDisplayLink?.invalidate()
            self.animateSelectEndDisplayLink = nil
        }

        self.modelEntity.model?.materials[0] = sphereMaterial
    }
    
    /// Animates the entity along the Y axis to create a subtle "bounce" animation.
    /// - Note: In the case the anchor targets a vertical plane, the animation will move the entity towards and back from the camera since the Y axis is perpendicular to the vertical plane.
    @objc private func animatePosition() {
        // If this sphere is selected, then freeze the position.
        // Otherwise, continue to animate per the specified increment.
        let increment = isSelected ? 0.0 : AnimationConstants.yPositionIncrement
        
        if self.increasingYPosition {
            self.modelEntity.transform.translation.y += increment
            self.yPositionDelta += increment
            
            if self.yPositionDelta >= AnimationConstants.maximumYDelta {
                self.yPositionDelta = 0.0
                self.increasingYPosition = false
            }
        } else {
            self.modelEntity.transform.translation.y -= increment
            self.yPositionDelta += increment

            if self.yPositionDelta >= AnimationConstants.maximumYDelta {
                self.yPositionDelta = 0.0
                self.increasingYPosition = true
            }
        }
    }
}
