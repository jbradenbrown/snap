//
//  SnapGestureModel.swift
//  Sparkler
//
//  Created by Jeffrey Brown on 3/30/24.
//

import ARKit
import SwiftUI
import RealityKit

/// A model that contains up-to-date hand coordinate information.
@MainActor
class SnapGestureModel: ObservableObject, @unchecked Sendable {
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    var lastSnapStart = Date()
    var lastSnapFinish = Date()
    var snapping = false
    var fireballing = false
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
        
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked
        else {
            return nil
        }
        
        guard let rightHandThumbTipPosition = rightHandAnchor.handSkeleton?.joint(.thumbTip),
              let rightHandMiddleFingerTip = rightHandAnchor.handSkeleton?.joint(.middleFingerTip),
              rightHandMiddleFingerTip.isTracked && rightHandThumbTipPosition.isTracked
        else {
            return nil
        }
        
        // Get the position of all joints in world coordinates.
        let originFromRightHandThumbTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandThumbTipPosition.anchorFromJointTransform
        ).columns.3.xyz
        
        let originFromRightHandMiddleFingerTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandMiddleFingerTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let tipDistance = distance(originFromRightHandThumbTipTransform, originFromRightHandMiddleFingerTipTransform)
        
        // Heart gesture detection is true when the distance between the index finger tips centers
        // and the distance between the thumb tip centers is each less than four centimeters.
        let isSnapStartGesture = tipDistance < 0.025
        if !isSnapStartGesture {
            return nil
        }
        
        lastSnapStart = Date()
        
        return lastSnapStart
        
    }
    
    func snapFinishGesture() -> SIMD3<Float>? {
        
        // Maybe change from tracking intermediate joints to tracking the end position which is index and thumb tip touching
        if !snapping && DateInterval(start: lastSnapStart, end: Date()).duration >= 0.5 {
            return nil
        }
        
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked
        else {
            return nil
        }
        
        guard let rightHandThumbIntermediateTip = rightHandAnchor.handSkeleton?.joint(.thumbIntermediateTip),
              let rightHandMiddleFingerIntermediateTip = rightHandAnchor.handSkeleton?.joint(.middleFingerIntermediateTip),
              let rightHandThumbTip = rightHandAnchor.handSkeleton?.joint(.thumbTip),
              rightHandMiddleFingerIntermediateTip.isTracked && rightHandThumbIntermediateTip.isTracked
        else {
            return nil
        }
        
        // Get the position of all joints in world coordinates.
        let originFromRightHandThumbIntermediateTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandThumbIntermediateTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let originFromRightHandMiddleFingerIntermediateTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandMiddleFingerIntermediateTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let absThumbTip = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandThumbTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let pointDistance = distance(originFromRightHandThumbIntermediateTipTransform, originFromRightHandMiddleFingerIntermediateTipTransform)
        
        // Heart gesture detection is true when the distance between the index finger tips centers
        // and the distance between the thumb tip centers is each less than four centimeters.
        let isSnapFinishGesture = pointDistance < 0.025
        if !isSnapFinishGesture {
            return nil
        }
        
        // Compute the position of the touching tips
        let half_distance = (originFromRightHandThumbIntermediateTipTransform - originFromRightHandMiddleFingerIntermediateTipTransform) / 2
        let midpoint = originFromRightHandMiddleFingerIntermediateTipTransform - half_distance
        
        
        snapping = true
        lastSnapFinish = Date()
        
        return absThumbTip
        
    }
    
    func doneSnapping() -> Bool {
        if !snapping {
            return false
        }
        
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked
        else {
            return false
        }
        
        guard let rightHandThumbTip = rightHandAnchor.handSkeleton?.joint(.thumbTip),
              let rightHandIndexFingerTip = rightHandAnchor.handSkeleton?.joint(.indexFingerTip),
              rightHandIndexFingerTip.isTracked && rightHandThumbTip.isTracked
        else {
            return false
        }
        
        // Get the position of all joints in world coordinates.
        let originFromRightHandThumbTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandThumbTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let originFromRightHandIndexFingerTipTransform = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandIndexFingerTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let tipDistance = distance(originFromRightHandThumbTipTransform, originFromRightHandIndexFingerTipTransform)
        
        let snapEnded = tipDistance > 0.1
        if !snapEnded {
            return false
        }
        
        snapCount += 1
        print(snapCount)
        
        snapping = false
        
        return true
    }
    
    func openPalm() -> (Float, SIMD3<Float>)? {
        
        // A palm is open when a hand is facing up, with distance between the tip of your thumb and the tip of your pinky
        if !fireballing && DateInterval(start: lastSnapFinish, end: Date()).duration >= 1.5 { //TODO MAKE BIGGER
            return nil
        }
        
        guard let rightHandAnchor = latestHandTracking.right,
              rightHandAnchor.isTracked
        else {
            return nil
        }
        
        guard let rightHandThumbTip = rightHandAnchor.handSkeleton?.joint(.thumbTip),
              let rightHandPinkyTip = rightHandAnchor.handSkeleton?.joint(.littleFingerTip),
              let rightHandIndexTip = rightHandAnchor.handSkeleton?.joint(.indexFingerTip),
                rightHandThumbTip.isTracked && rightHandPinkyTip.isTracked && rightHandIndexTip.isTracked
        else {
            return nil
        }
        
        let originFromRightHandThumbTip = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandThumbTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let originFromRightHandPinkyTip = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandPinkyTip.anchorFromJointTransform
        ).columns.3.xyz
        
        let originFromRightHandIndexTip = matrix_multiply(
            rightHandAnchor.originFromAnchorTransform, rightHandIndexTip.anchorFromJointTransform
        ).columns.3.xyz
        
        if distance(originFromRightHandIndexTip, originFromRightHandThumbTip) <= 0.05 {
            return nil
        }
        
        let coplanar1 = normalize(originFromRightHandThumbTip - originFromRightHandPinkyTip)
        let coplanar2 = normalize(originFromRightHandPinkyTip - originFromRightHandIndexTip)
        
        let plane = normalize(cross(coplanar1, coplanar2))
        
        let isOpenPalm = plane[1] < -0.50
        if !isOpenPalm {
            fireballing = false
            return nil
        }
        
        fireballing = true
        
        let center = (originFromRightHandIndexTip + originFromRightHandPinkyTip + originFromRightHandThumbTip) / 3
        let size = distance(originFromRightHandThumbTip, center)
        
        return (size, center)
    }
    
    func isFireballing() -> Bool {
        return fireballing
    }
}
