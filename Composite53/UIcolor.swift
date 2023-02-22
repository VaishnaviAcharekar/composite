//
//  UIcolor.swift
//  Composite53
//
//  Created by user on 16/02/23.
//

import Foundation
import UIKit



extension UIView {
    
    func setGradientBackground1(colors: [UIColor]) {
        let updatedFrame = bounds
        let gradientLayer = CAGradientLayer(frame: updatedFrame, colors: colors)
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        self.clipsToBounds = false
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

extension UIColor{
    
    
    static let lightingPurpleColor = UIColor(hexString: "#1546A0")
    
    
    
    
}

public extension UIColor{
    
    
    convenience init(hexString: String) {
        let hexString: String = (hexString as NSString).trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString as String)

        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)

        let mask = 0x000000FF
        let rPortion = Int(color >> 16) & mask
        let gPortion = Int(color >> 8) & mask
        let bPortion = Int(color) & mask

        let red = CGFloat(rPortion) / 255.0
        let green = CGFloat(gPortion) / 255.0
        let blue = CGFloat(bPortion) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
}
