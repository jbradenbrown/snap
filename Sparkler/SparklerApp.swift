//
//  SparklerApp.swift
//  Sparkler
//
//  Created by Jeffrey Brown on 3/30/24.
//

import SwiftUI

@main
struct SparklerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(gestureModel: SnapGestureModelContainer.snapGestureModel)
        }.immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}

@MainActor
enum SnapGestureModelContainer {
    private(set) static var snapGestureModel = SnapGestureModel()
}
