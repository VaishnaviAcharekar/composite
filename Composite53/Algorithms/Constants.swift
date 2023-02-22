//
//  Constants.swift
//  GLUV-body-scan-native
//
//  Created by Saurabh Mohrir on 19/09/22.
//

import Foundation

class Constants
{
    static let twoPi = 2 * Float.pi
    static let piByOneEighty = Float.pi / 180.0
    static let oneEightyByPi = 180.0 / Float.pi
    
    static let DeltaHeight: Float = 0.01
    static let DeltaAngle: Float = 5
    static let XIncrement: Float = 0.02
    static let PointCountThreshold: Int = 2
    static let UnderbustDecrementThreshold: Float = -0.35
    static let ThicknessThreshold: Float = 0.005
    
    // Double layer detection
    static let MaxAllowedDistanceBetweenConsecutivePoints: Float = 0.02
    static let StartAngle: Float = -170.0
    static let EndAngle: Float = -10.0
    static let MinThresholdForPatchToBeInDoubleLayer: Int = 50
    static let MaximumViolationsAllowed: Int = 200
}
