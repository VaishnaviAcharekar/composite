//
//  BodyMeasurements.swift
//  Ditto
//
//  Created by Saurabh Mohrir on 14/09/22.
//

import Foundation
import SceneKit

class BodyMeasurements
{
    static var Instance = BodyMeasurements()
    
    var TopMostY: Float = 0.0
    var BottomMostY: Float = 0.0
    var ShoulderPoint: Float = -999.0
    
    let UserMarkerUnderbustPositionString: String = "initialUserMarkedUnderBustPos"
    let UnderbustThicknessString: String = "underbustThickness"
    
    var initialUserMarkerUnderBustPosition: Float = 0.0
    var underbustThickness: Float = 0.0
    var UnderbustHeight: Float = 0.0
    {
        didSet
        {
            print("BodyMeasurements.Instance.UnderbustHeight \(UnderbustHeight)")
            CurrentUnderbustHeightWrtBottom = UnderbustHeight - BottomMostY
        }
    }
    var UnderbustMeasurement: Float = 0.0
    var BustHeight: Float = 0.0
    var BustMeasurement: Float = 0.0
    var BustDetected: Bool = true
    
    var Empty: Float = -999.0
    var scanStatusMessage: String = ""
    
    var DetectionAndMeasurementStatus: Bool = true
    {
        didSet
        {
//            Debugger.show(type: DebugType.log, val: "DetectionAndMeasurementStatus", log: "changed to \(DetectionAndMeasurementStatus)")
        }
    }
    
    var tempUnderArmpointHeight: Float = 0
    
    var DefaultCalculatedUnderbustHeightWrtCenter: Float = 0
    var DefaultCalculatedUnderbustHeightWrtBottom: Float = 0
    var DefaultCalculatedBustHeightWrtBottom: Float = 0
    var DefaultCalculatedBustHeightWrtCenter: Float = 0
    
    var CurrentUnderbustHeightWrtBottom: Float = 0
    {
        didSet
        {
            print("BodyMeasurements.Instance.CurrentUnderbustHeightWrtBottom \(CurrentUnderbustHeightWrtBottom)")
            if CurrentUnderbustHeightWrtBottom < 0
            {
                DetectionAndMeasurementStatus = false
            }
        }
    }
    
    static let MetreToInches: Float = 39.3701
    
    init() {
        ResetValues()
    }
    
    func ResetTopmostAndBottommostY(_ point: [SCNVector3], resetValues shouldReset: Bool)
    {
        if shouldReset
        {
            ResetValues()
        }
        DetectionAndMeasurementStatus = true
        ShoulderPoint = Empty
        
        if point.isEmpty
        {
            TopMostY = Empty
            BottomMostY = Empty
            return
        }
        
        TopMostY = point[0].y
        BottomMostY = point[0].y
        
        for i in stride(from: 1, to: point.count, by: 1)
        {
            let pnt = point[i]
            if TopMostY < pnt.y
            {
                TopMostY = pnt.y
            }
            else if BottomMostY > pnt.y
            {
                BottomMostY = pnt.y
            }
        }
    }
    
    func ResetValues()
    {
        TopMostY = -99
        BottomMostY = 99
        ShoulderPoint = TopMostY
        UnderbustHeight = 0
        BustHeight = 0
        BustMeasurement = 0
        UnderbustMeasurement = 0
        scanStatusMessage = ""
        DetectionAndMeasurementStatus = true
        tempUnderArmpointHeight = 0
    }
    
}
