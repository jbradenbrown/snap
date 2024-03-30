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
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)

                // Add an ImageBasedLight for the immersive content
                guard let resource = try? await EnvironmentResource(named: "ImageBasedLight") else { return }
                let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
                immersiveContentEntity.components.set(iblComponent)
                immersiveContentEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: immersiveContentEntity))

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
            
            print("Running")
            
            var particles = ParticleEmitterComponent()
            particles.emitterShape = .plane
            particles.emitterShapeSize = [1,1,1] * 0.05

            particles.mainEmitter.birthRate = 2000
            particles.mainEmitter.size = 0.05
            particles.mainEmitter.lifeSpan = 0.5
            particles.mainEmitter.color = .evolving(
                start: .single(.blue),
                end: .single(.red))
            particles.mainEmitter.angleVariation = 0.2
            
            particlesEntity.components.set(particles)

            content.add(particlesEntity)
            
        } update: { updateContent in
            _ = gestureModel.snapStartGesture()
            
            if let sparkOrigin = gestureModel.snapFinishGesture() {
                particlesEntity.transform.translation = SIMD3<Float>(sparkOrigin)
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
