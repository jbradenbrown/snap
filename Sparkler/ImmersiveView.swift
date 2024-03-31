//
//  ImmersiveView.swift
//  Sparkler
//
//  Created by Jeffrey Brown on 3/30/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Accelerate

struct ImmersiveView: View {
    @ObservedObject var gestureModel: SnapGestureModel
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
//            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
//                content.add(immersiveContentEntity)
//
//                // Add an ImageBasedLight for the immersive content
////                guard let resource = try? await EnvironmentResource(named: "ImageBasedLight") else { return }
////                let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
////                immersiveContentEntity.components.set(iblComponent)
////                immersiveContentEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: immersiveContentEntity))
//
//                // Put skybox here.  See example in World project available at
//                // https://developer.apple.com/
//            }
            
            var particles = ParticleEmitterComponent()
            particles.emitterShape = .point
            particles.emitterShapeSize = [1,1,1] * 0.05

            particles.mainEmitter.birthRate = 2000
            particles.mainEmitter.size = 0.05
            particles.mainEmitter.lifeSpan = 0.1
            particles.mainEmitter.color = .evolving(
                start: .single(.blue),
                end: .single(.red))
            particles.mainEmitter.angleVariation = 0.05
            
            particlesEntity.components.set(particles)

            content.add(particlesEntity)
            
        } update: { updateContent in
            
            _ = gestureModel.snapStartGesture()
            
            if let sparkOrigin = gestureModel.snapFinishGesture() {
                particlesEntity.transform.translation = SIMD3<Float>(sparkOrigin)
                
                if snapCount > 3 {
                    var particles = ParticleEmitterComponent()
                    particles.emitterShape = .point
                    particles.emitterShapeSize = [1,1,1] * 0.05
                    
                    particles.mainEmitter.birthRate = 2000
                    particles.mainEmitter.size = 0.05
                    particles.mainEmitter.lifeSpan = 0.1
                    particles.mainEmitter.color = .evolving(
                        start: .single(.blue),
                        end: .single(.red))
                    particles.mainEmitter.angleVariation = 0.05
                    
                    particlesEntity.components.set(particles)
                } else {
                    var particles = ParticleEmitterComponent()
                    particles.emitterShape = .point
                    particles.emitterShapeSize = [1,1,1] * 0.05
                    
                    particles.mainEmitter.birthRate = 0
                    particles.mainEmitter.size = 0.05
                    particles.mainEmitter.lifeSpan = 0.1
                    particles.mainEmitter.color = .constant(.single(.yellow))
                    particles.mainEmitter.angleVariation = 0.05
                    
                    particlesEntity.components.set(particles)
//                    particlesEntity.components[ParticleEmitterComponent]
                }
            } else if gestureModel.doneSnapping() {
                print("done snapping")
                
                var particles = ParticleEmitterComponent()
                particles.emitterShape = .point
                particles.emitterShapeSize = [1,1,1] * 0.05

                particles.mainEmitter.birthRate = 0
                particles.mainEmitter.size = 0.05
                particles.mainEmitter.lifeSpan = 0.1
                particles.mainEmitter.color = .evolving(
                    start: .single(.blue),
                    end: .single(.red))
                particles.mainEmitter.angleVariation = 0.05
                
                particlesEntity.components.set(particles)
            } else if let (sparkSize, sparkOrigin) = gestureModel.openPalm() {
                particlesEntity.transform.translation = SIMD3<Float>(sparkOrigin)
                
                var particles = ParticleEmitterComponent()
                particles.emitterShape = .sphere
                particles.emitterShapeSize = [1,1,1] * sparkSize
                particles.birthDirection = ParticleEmitterComponent.BirthDirection.world
                particles.mainEmitter.birthRate = 4000
                particles.mainEmitter.size = 0.05
                particles.mainEmitter.lifeSpan = 0.1
                particles.mainEmitter.color = .evolving(
                    start: .single(.blue),
                    end: .single(.red))
                particles.mainEmitter.angleVariation = 0.2
                
                particlesEntity.components.set(particles)
                
                // Add physics and see if it works?
                
                
            } else if !gestureModel.isFireballing() {
//                print("done snapping")
                
                var particles = ParticleEmitterComponent()
                particles.emitterShape = .point
                particles.emitterShapeSize = [1,1,1] * 0.05

                particles.mainEmitter.birthRate = 0
                particles.mainEmitter.size = 0.05
                particles.mainEmitter.lifeSpan = 0.1
                particles.mainEmitter.color = .evolving(
                    start: .single(.blue),
                    end: .single(.red))
                particles.mainEmitter.angleVariation = 0.05
                
                particlesEntity.components.set(particles)
            }
            
        }
        .task {
            await gestureModel.start()
        }
        .task {
            await gestureModel.publishHandTrackingUpdates()
        }
        .task {
            await gestureModel.monitorSessionEvents()
        }
    }
}

//#Preview(immersionStyle: .full) {
//    ImmersiveView()
//}
