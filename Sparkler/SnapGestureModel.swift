//
//  SnapGestureModel.swift
//  Sparkler
//
//  Created by Jeffrey Brown on 3/30/24.
//

import ARKit
import SwiftUI

/// A model that contains up-to-date hand coordinate information.
@MainActor
class SnapGestureModel: ObservableObject, @unchecked Sendable {
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    var lastSnapStart = Date()
    @Published var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    func start() async {
        do {
            if HandTrackingProvider.isSupported {
                print("ARKitSession starting.")
                try await session.run([handTracking])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func publishHandTrackingUpdates() async {
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                
                // Publish updates only if the hand and the relevant joints are tracked.
                guard anchor.isTracked else { continue }
                
                // Update left hand info.
                if anchor.chirality == .left {
                    latestHandTracking.left = anchor
                } else if anchor.chirality == .right { // Update right hand info.
                    latestHandTracking.right = anchor
                }
            default:
                break
            }
        }
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                    // Stop the game, ask the user to grant hand tracking authorization again in Settings.
                }
            default:
                print("Session event \(event)")
            }
        }
    }
    
    
    func snapStartGesture() -> Date? {
        print("Start snap")
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked
        else {
            return nil
        }
        
        guard let rightHandThumbTipPosition = rightHandAnchor.handSkeleton?.joint(.thumbTip),
              let rightHandIndexFingerTip = rightHandAnchor.handSkeleton?.joint(.indexFingerTip),
              rightHandIndexFingerTip.isTracked && rightHandThumbTipPosition.isTracked
        else {
            return nil
        }
        
        // Get the position of all joints in world coordinates.
        let originFromRightHandThumbTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandThumbTipPosition.anchorFromJointTransform
        ).columns.3.xyz
        
        let originFromRightHandIndexFingerTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandIndexFingerTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let tipDistance = distance(originFromRightHandThumbTipTransform, originFromRightHandIndexFingerTipTransform)
        
        // Heart gesture detection is true when the distance between the index finger tips centers
        // and the distance between the thumb tip centers is each less than four centimeters.
        let isSnapStartGesture = tipDistance < 0.02
        if !isSnapStartGesture {
            return nil
        }
        
        lastSnapStart = Date()
        
        return lastSnapStart
        
    }
    
    func snapFinishGesture() -> SIMD3<Float>? {
        print("Finish snap")
        if DateInterval(start: lastSnapStart, end: Date()).duration >= 0.5 {
            return nil
        }
        
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked
        else {
            return nil
        }
        
        guard let rightHandThumbIntermediateTip = rightHandAnchor.handSkeleton?.joint(.thumbIntermediateTip),
              let rightHandIndexFingerIntermediateTip = rightHandAnchor.handSkeleton?.joint(.indexFingerIntermediateTip),
              rightHandIndexFingerIntermediateTip.isTracked && rightHandThumbIntermediateTip.isTracked
        else {
            return nil
        }
        
        // Get the position of all joints in world coordinates.
        let originFromRightHandThumbIntermediateTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandThumbIntermediateTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let originFromRightHandIndexFingerIntermediateTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandIndexFingerIntermediateTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let pointDistance = distance(originFromRightHandThumbIntermediateTipTransform, originFromRightHandIndexFingerIntermediateTipTransform)
        
        // Heart gesture detection is true when the distance between the index finger tips centers
        // and the distance between the thumb tip centers is each less than four centimeters.
        let isSnapFinishGesture = pointDistance < 0.03
        if !isSnapFinishGesture {
            return nil
        }
        
        // Compute the position of the touching tips
        let half_distance = (originFromRightHandThumbIntermediateTipTransform - originFromRightHandIndexFingerIntermediateTipTransform) / 2
        let midpoint = originFromRightHandIndexFingerIntermediateTipTransform - half_distance
        
        return midpoint
        
    }
}
