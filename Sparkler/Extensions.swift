//
//  Extensions.swift
//  Sparkler
//
//  Created by Jeffrey Brown on 3/30/24.
//

import SwiftUI
import RealityKit

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}
