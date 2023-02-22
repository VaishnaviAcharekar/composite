//
//  StaticAlgos.swift
//  GLUV-body-scan-native
//
//  Created by Apple on 14/09/22.
//

import Foundation
import SceneKit

class StaticAlgos
{
    static func GetCentroid(_ points: [simd_float3]) -> simd_float3
    {
        if points.isEmpty { return simd_float3(0, 0, 0) }
        
        var sum = points[0]
        let n = points.count
        
        for i in stride(from: 1, to: n, by: 1)
        {
            sum += points[i]
        }
        let centroid = simd_float3(sum.x / Float(n), sum.y / Float(n), sum.z / Float(n))
        
        return centroid
    }
    
    static func GetCentroid(_ points: [SCNVector3]) -> SCNVector3
    {
        if points.isEmpty { return SCNVector3(0, 0, 0) }
        
        var sum = points[0]
        let n = points.count
        
        for i in stride(from: 1, to: n, by: 1)
        {
            sum += points[i]
        }
        let centroid = SCNVector3(sum.x / Float(n), sum.y / Float(n), sum.z / Float(n))
        
        return centroid
    }
    
    static func GetAveregedOuterPoints(_ pointAtAGivenY: [SCNVector3]) -> [SCNVector3]
    {
        var smoothfinalpoint = [SCNVector3]()
        if pointAtAGivenY.count == 0
        {
            return smoothfinalpoint
        }
        
        var avaragedfinalpoint = [SCNVector3]()
        let count = pointAtAGivenY.count
        let centroid = GetCentroid(pointAtAGivenY)
        
        for i in stride(from: 0, to: count, by: 1)
        {
            avaragedfinalpoint.append(pointAtAGivenY[i] - centroid)
        }
        
        avaragedfinalpoint.sort { atan2($0.z, $0.x) < atan2($1.z, $1.x) }
        
        var indexofLastMaxanglePoints = 0
        let angleIncrementPerLoop: Float = 6
        var angleToCheck: Float = -180
        
        while angleToCheck < 180
        {
            var pointsAtAnAngle = [SCNVector3]()
            while indexofLastMaxanglePoints < avaragedfinalpoint.count
            {
                if (Constants.oneEightyByPi * atan2(avaragedfinalpoint[indexofLastMaxanglePoints].z, avaragedfinalpoint[indexofLastMaxanglePoints].x)) >= (angleToCheck + angleIncrementPerLoop)
                {
                    break
                }
                pointsAtAnAngle.append(avaragedfinalpoint[indexofLastMaxanglePoints])
                indexofLastMaxanglePoints += 1
            }
            
            if pointsAtAnAngle.isEmpty == false
            {
                //Debugger.show(type: DebugType.log, log: "PointsAtAngleCount : \(pointsAtAnAngle.count) : \(avaragedfinalpoint.count) ")
                //                var sum1 = pointsAtAnAngle[0]
                //                var avgPoint = pointsAtAnAngle[0]
                //                let count = pointsAtAnAngle.count
                //                for i in stride(from: 1, to: count, by: 1)
                //                {
                //                    sum1 = sum1 + pointsAtAnAngle[i]
                //                }
                //
                //                avgPoint.x = sum1.x / Float(count)
                //                avgPoint.y = sum1.y / Float(count)
                //                avgPoint.z = sum1.z / Float(count)
                let avgPoint = GetCentroid(pointsAtAnAngle)
                
                smoothfinalpoint.append(avgPoint)
            }
            angleToCheck += angleIncrementPerLoop
        }
        return smoothfinalpoint
    }
    
    static func GetCircumferenceOfPoints(pts points: [SCNVector3]) -> Float
    {
        if points.isEmpty
        {
            return Float(0)
        }
        
        let n = points.count
        
        var circumference: Float = 0.0
        
        if n > 1
        {
            for i in stride(from: 0, to: n-1, by: 1)
            {
                let v1 = SCNVector3(x: points[i].x, y: 0, z: points[i].z)
                let v2 = SCNVector3(x: points[i+1].x, y: 0, z: points[i+1].z)
                let distance1 = v1.distance(toVector: v2)
                circumference += distance1
            }
            
            let v1 = SCNVector3(x: points[n-1].x, y: 0, z: points[n-1].z)
            let v2 = SCNVector3(x: points[0].x, y: 0, z: points[0].z)
            let distance1 = v1.distance(toVector: v2)
            circumference += distance1
        }
        
        return circumference
    }
    
    static func GetCircumferenceOfBustPoints(bustPoints points: [SCNVector3]) -> Float
    {
        var pointsSortedAtPosZ = points.filter { $0.z <= 0 }
        
        if pointsSortedAtPosZ.count < 2
        {
            return Float(0)
        }
        
        pointsSortedAtPosZ.sort { $0.x < $1.x }
        
        let averagePos: Float = (pointsSortedAtPosZ[0].x + pointsSortedAtPosZ[pointsSortedAtPosZ.count - 1].x) / 2
        
        var leftHalf = [SCNVector3]()
        var rightHalf = [SCNVector3]()
        
        for point in pointsSortedAtPosZ
        {
            if point.x > averagePos
            {
                leftHalf.append(point)
            }
            else
            {
                rightHalf.append(point)
            }
        }
        
        leftHalf.sort { $0.z < $1.z }
        rightHalf.sort { $0.z < $1.z }
        
        var leftHightest = SCNVector3()
        var rightHighest = SCNVector3()
        
        leftHightest = leftHalf[0]
        rightHighest = rightHalf[0]
        
        let excludedPointsWithinTopPos1 = pointsSortedAtPosZ.filter { $0.z < 0}
        
        let excludedPointsWithinTopPos = excludedPointsWithinTopPos1.filter {
            (
                $0.x > leftHightest.x || $0.x < rightHighest.x
            )
        }
        let pointsAtPositiveZ = points.filter { $0.z >= 0 }
        
        var allPointsExcludingWithinTop = [SCNVector3]()
        allPointsExcludingWithinTop.append(contentsOf: pointsAtPositiveZ)
        allPointsExcludingWithinTop.append(contentsOf: excludedPointsWithinTopPos)
        
        var _points = allPointsExcludingWithinTop
        _points.sort { atan2( $0.z, $0.x) < atan2( $1.z, $1.x) }
        
        return GetCircumferenceOfPoints(pts: _points)
    }
    
    static func FindDoubleLayerAndRemove2ndLayer(_ points: [SCNVector3]) -> [SCNVector3]
    {
        var finalPoints = [SCNVector3]()
        let upperExtreamY = BodyMeasurements.Instance.TopMostY
        let lowerExtreamY = BodyMeasurements.Instance.BottomMostY
        let deltaHeight: Float = 0.01
        let angleIncrementPerLoop: Float = 5.0
        var lowerLimit = lowerExtreamY
        
        while lowerLimit < upperExtreamY
        {
            var pointsAtGivenY = points.filter { $0.y >= lowerLimit && $0.y < lowerLimit + deltaHeight }
            
            if pointsAtGivenY.isEmpty == false
            {
                pointsAtGivenY.sort { atan2($0.z, $0.x) < atan2($1.z, $1.x) }
                
                var angleToCheck: Float = -180
                var indexofLastMaxanglePoints = 0
                
                while angleToCheck < 180
                {
                    var pointsAtAnAngle = [SCNVector3]()
                    while indexofLastMaxanglePoints < pointsAtGivenY.count
                    {
                        let point = pointsAtGivenY[indexofLastMaxanglePoints]
                        if (Constants.oneEightyByPi * atan2(point.z, point.x)) >= (angleToCheck + angleIncrementPerLoop)
                        {
                            break
                        }
                        pointsAtAnAngle.append(point)
                        indexofLastMaxanglePoints += 1
                    }
                    
                    if pointsAtAnAngle.isEmpty == false
                    {
                        let sortedPointsAtTheHeight = pointsAtAnAngle.sorted { $0.lengthSquared < $1.lengthSquared }
                        let doubleLayerIndex = CheckForDoubleLayerVerticalForAvatrSM(sortedPointsAtTheHeight)
                        
                        if doubleLayerIndex >= 0
                        {
                            finalPoints.append(contentsOf: sortedPointsAtTheHeight[0...doubleLayerIndex])
                        }
                        else
                        {
                            finalPoints.append(contentsOf: sortedPointsAtTheHeight)
                        }
                    }
                    angleToCheck += angleIncrementPerLoop
                }
            }
            
            lowerLimit += deltaHeight
        }
        
        return finalPoints
    }
    
    static func CheckForDoubleLayerVerticalForAvatrSM(_ avatarMiddleCutout: [SCNVector3]) -> Int
    {
        let ThicknessThreshold = pow(Constants.ThicknessThreshold, 2)
        var layerId = [Int]()
        let points = avatarMiddleCutout
        
        if points.isEmpty == false
        {
            var d1 = points[0].lengthSquared
            let N = points.count
            
            for i in stride(from: 1, to: N, by: 1)
            {
                let d2 = points[i].lengthSquared
                let pointZDistance = d2 - d1
                
                if abs(pointZDistance) > ThicknessThreshold
                {
                    let percentage = Float(i) / Float(N)
                    if percentage > 0.3 && percentage < 0.7
                    {
                        if percentage > 0.5
                        {
                            layerId.append(1)
                        }
                        else
                        {
                            layerId.append(2)
                        }
                        return i
                    }
                }
                
                d1 = d2
            }
        }
        return -1
    }
    
    static func RemoveNoisyPoints(_ points: [SCNVector3], _ rh: Float = 0.2, _ rV: Float = 0.1) -> [SCNVector3]
    {
        var newPoints = [SCNVector3]()
        var pointsAtHeightsList = GetPointsHeightWise(points)
        
        for hIndex in stride(from: 0, to: pointsAtHeightsList.count, by: 1)
        {
            while(pointsAtHeightsList[hIndex].count > 0)
            {
                let point = pointsAtHeightsList[hIndex][0]
                pointsAtHeightsList[hIndex].remove(at: 0)
                
                var localPoints = [SCNVector3]()
                var localPointsIndex = [Int]()
                var localPoint0U = [SCNVector3]()
                var localPoint0UIndex = [Int]()
                var localPoint0D = [SCNVector3]()
                var localPoint0DIndex = [Int]()
                
                localPoints.append(point)
                
                let pt1 = SCNVector3(x: point.x, y: 0, z: point.z)
                
                var idx = 0
                for pt in pointsAtHeightsList[hIndex]
                {
                    let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                    if pt1.distance(toVector: pt2) < rh && abs(pt.y - point.y) < rV
                    {
                        localPoints.append(pt)
                        localPointsIndex.append(idx)
                    }
                    idx += 1
                }
                
                idx = 0
                if hIndex > 0
                {
                    for pt in pointsAtHeightsList[hIndex - 1]
                    {
                        let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                        if pt1.distance(toVector: pt2) < rh && abs(pt.y - point.y) < rV
                        {
                            localPoint0U.append(pt)
                            localPoint0UIndex.append(idx)
                        }
                        idx += 1
                    }
                }
                
                idx = 0
                if (hIndex < pointsAtHeightsList.count - 1)
                {
                    for pt in pointsAtHeightsList[hIndex + 1]
                    {
                        let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                        if pt1.distance(toVector: pt2) < rh && abs(pt.y - point.y) < rV
                        {
                            localPoint0D.append(pt)
                            localPoint0DIndex.append(idx)
                        }
                        idx += 1
                    }
                }
                
                
                if localPoints.count + localPoint0U.count + localPoint0D.count > 5
                {
                    newPoints.append(contentsOf: localPoints)
                    newPoints.append(contentsOf: localPoint0U)
                    newPoints.append(contentsOf: localPoint0D)
                }
                
                localPointsIndex = localPointsIndex.reversed()
                localPoint0UIndex = localPoint0UIndex.reversed()
                localPoint0DIndex = localPoint0DIndex.reversed()
                
                for idx in localPointsIndex
                {
                    pointsAtHeightsList[hIndex].remove(at: idx)
                }
                
                for idx in localPoint0UIndex
                {
                    pointsAtHeightsList[hIndex - 1].remove(at: idx)
                }
                
                for idx in localPoint0DIndex
                {
                    pointsAtHeightsList[hIndex + 1].remove(at: idx)
                }
            }
        }
        
        return newPoints
    }
    
    static func SmmothOutPointsHorizontally(_ points: [SCNVector3], _ rh: Float = 0.02, _ rV: Float = 0.01) -> [SCNVector3]
    {
        var newPoints = [SCNVector3]()
        var pointsAtHeightsList = GetPointsHeightWise(points)
        
        for hIndex in stride(from: 0, to: pointsAtHeightsList.count, by: 1)
        {
            while pointsAtHeightsList[hIndex].count > 0
            {
                let point = pointsAtHeightsList[hIndex][0]
                pointsAtHeightsList[hIndex].remove(at: 0)
                
                var localPoints = [SCNVector3]()
                var localPointsIndex = [Int]()
                var localPoint0U = [SCNVector3]()
                var localPoint0UIndex = [Int]()
                var localPoint0D = [SCNVector3]()
                var localPoint0DIndex = [Int]()
                
                localPoints.append(point)
                
                var idx = 0
                let pt1 = SCNVector3(x: point.x, y: 0, z: point.z)
                
                for pt in pointsAtHeightsList[hIndex]
                {
                    let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                    if pt1.distance(toVector: pt2) < rh && (abs(pt.y-point.y) < rV)
                    {
                        localPoints.append(pt)
                        localPointsIndex.append(idx)
                    }
                    idx += 1
                }
                
                idx = 0
                if hIndex > 0
                {
                    for pt in pointsAtHeightsList[hIndex - 1]
                    {
                        let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                        if pt1.distance(toVector: pt2) < rh && abs(pt.y-point.y) < rV
                        {
                            localPoint0U.append(pt)
                            localPoint0UIndex.append(idx)
                        }
                        idx += 1
                    }
                }
                
                idx = 0
                if (hIndex < pointsAtHeightsList.count - 1)
                {
                    for pt in pointsAtHeightsList[hIndex + 1]
                    {
                        let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.y)
                        if pt1.distance(toVector: pt2) < rh && abs(pt.y-point.y) < rV
                        {
                            localPoint0D.append(pt)
                            localPoint0DIndex.append(idx)
                        }
                        idx += 1
                    }
                }
                
                //                var avgPoint = SCNVector3()
                //
                //                for i in 0..<localPoints.count
                //                {
                //                    avgPoint = avgPoint + localPoints[i]
                //                }
                //
                //                for i in 0..<localPoint0U.count
                //                {
                //                    avgPoint = avgPoint + localPoint0U[i]
                //                }
                //
                //                for i in 0..<localPoint0D.count
                //                {
                //                    avgPoint = avgPoint + localPoint0D[i]
                //                }
                var avgPoint = localPoints.reduce(SCNVector3(0, 0, 0), +) + localPoint0U.reduce(SCNVector3(0, 0, 0), +) + localPoint0D.reduce(SCNVector3(0, 0, 0), +)
                
                let n = Float(localPoints.count + localPoint0U.count + localPoint0D.count)
                
                avgPoint.x = avgPoint.x / n
                avgPoint.y = avgPoint.y / n
                avgPoint.z = avgPoint.z / n
                newPoints.append(avgPoint)
                
                localPointsIndex = localPointsIndex.reversed()
                localPoint0UIndex = localPoint0UIndex.reversed()
                localPoint0DIndex = localPoint0DIndex.reversed()
                
                for idx in localPointsIndex
                {
                    pointsAtHeightsList[hIndex].remove(at: idx)
                }
                
                for idx in localPoint0UIndex
                {
                    pointsAtHeightsList[hIndex - 1].remove(at: idx)
                }
                
                for idx in localPoint0DIndex
                {
                    pointsAtHeightsList[hIndex + 1].remove(at: idx)
                }
                
            }
        }
        
        return newPoints
    }
    
    public static func GetPointsHeightWise(_ points: [SCNVector3]) -> [[SCNVector3]]
    {
        var pointsAtHeightsList = [[SCNVector3]]()
        
        if points.count == 0 || points.count < 2
        {
            return pointsAtHeightsList
        }
        
        var newPoints = [SCNVector3]()
        for point in points
        {
            newPoints.append(point)
        }
        
        newPoints.sort { $0.y > $1.y }
        
        var currentHeight = newPoints[0].y
        var lastHeightStartIndex = 0
        
        for i in stride(from: 0, to: newPoints.count, by: 1)
        {
            if newPoints[i].y <= currentHeight - 0.01
            {
                var pointsAtAHeight = [SCNVector3]()
                
                for j in stride(from: lastHeightStartIndex, to: i, by: 1)
                {
                    pointsAtAHeight.append(newPoints[j])
                }
                
                if pointsAtAHeight.count == 0
                {
                    pointsAtAHeight = [SCNVector3]()
                }
                
                pointsAtHeightsList.append(pointsAtAHeight)
                lastHeightStartIndex = i
                currentHeight = currentHeight - 0.01
            }
        }
        
        if lastHeightStartIndex < newPoints.count
        {
            var pointsAtAHeight = [SCNVector3]()
            let diff = abs(newPoints.count-lastHeightStartIndex)
            for j in stride(from: lastHeightStartIndex, to: lastHeightStartIndex + diff, by: 1)
            {
                pointsAtAHeight.append(newPoints[j])
            }
            if pointsAtAHeight.count == 0
            {
                pointsAtAHeight = [SCNVector3]()
            }
            pointsAtHeightsList.append(pointsAtAHeight)
        }
        
        return pointsAtHeightsList
    }
    
    static func LoadPointsFromFile(path _path: String, reverseZ _reverseZ: Bool = false) -> [SCNVector3]
    {
        var array = [SCNVector3]()
        let filePath = _path.deletingFilePrefix()
        
        if !FileManager.default.fileExists(atPath: filePath)
        {
            print("invalid path", filePath)
//            Debugger.show(type: DebugType.log, val: "invalid path", log: filePath)
            return array
        }
        
        let contents = try! String(contentsOfFile: filePath)
        // Split the file into separate lines
        let lines = contents.split(separator:"\r\n")
        
        //        if lines.count < 10
        //        {
        //            lines = contents.split(separator: "\n")
        //        }
        
        // Iterate over each line and print the line
        var i = 0
        for line in lines
        {
            if (i > 10)
            {
                let line11 = String(line)
                let bbb = line11.components(separatedBy: " ")
                let x = Float(bbb[1])!
                let y = Float(bbb[2])!
                var z = Float(bbb[3])!
                if _reverseZ
                {
                    z *= -1
                }
                array.append(SCNVector3(x: x, y: y, z: z))
            }
            i += 1
        }
        
        return array
    }
    
    static func GetPointsOfAvatarWithinAngleRange(_ points: [SCNVector3], _ startingAngle: Float, _ endingAngle: Float) -> [SCNVector3]
    {
        let lowerBound = BodyMeasurements.Instance.BottomMostY + 0.25
        var upperBound: Float
        
        if (BodyMeasurements.Instance.ShoulderPoint != 0)
        {
            upperBound = BodyMeasurements.Instance.ShoulderPoint
        }
        else
        {
            upperBound = BodyMeasurements.Instance.TopMostY
        }
        
        let startAngle = startingAngle
        let endAngle = endingAngle
        let pointsWithinTheYSection = points.filter { $0.y < upperBound && $0.y >= lowerBound }
        let count = pointsWithinTheYSection.count
        if count < 10
        {
            return [SCNVector3]()
        }
        
        let centroidOfSection = GetCentroid(pointsWithinTheYSection)
        
        var pointsWithAngle = [PointWithAngle]()
        
        for point in pointsWithinTheYSection
        {
            let radian = atan2(point.z, point.x)
            let degree = radian * Constants.oneEightyByPi
            let temp = PointWithAngle(point: point, angle: degree, dist: abs(point.distance(toVector: centroidOfSection)))
            pointsWithAngle.append(temp)
        }
        
        pointsWithAngle.sort(by: { $0.angle < $1.angle })
        
        let pointsWithinSection = pointsWithAngle.filter { $0.angle >= startAngle && $0.angle <= endAngle }.sorted(by: { $0.dist < $1.dist } )
        
        var pointsToConsider = [SCNVector3]()
        
        for i in stride(from: 0, to: pointsWithinSection.count, by: 1)
        {
            pointsToConsider.append(pointsWithinSection[i].point)
        }
        
        return pointsToConsider
    }
    
}

class PointWithAngle
{
    let point: SCNVector3
    let angle: Float
    let dist: Float
    
    init()
    {
        point = SCNVector3()
        angle = 0.0
        dist = 0.0
    }
    
    init(point v: SCNVector3, dist d: Float)
    {
        point = v
        dist = d
        angle = 0
    }
    
    init(point v: SCNVector3, angle a: Float, dist d: Float)
    {
        point = v
        angle = a
        dist = d
    }
}
