//
//  BKColorExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/5/23.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit
import CoreGraphics

public extension UIColor {
    
    /// 使用一个32位非负整数初始化颜色，格式为RGBA,如0x123456ff red: 0x12 green:0x34 blue:0x56 alpha 0xff
    ///
    /// - Parameters:
    ///   - number: 颜色对应的整数
    convenience init(number: UInt32) {
        
        let red = CGFloat(UInt8(number >> 24))/255.0
        let green = CGFloat(UInt8(number >> 16 & 0xff))/255.0
        let blue = CGFloat(UInt8(number >> 8 & 0xff))/255.0
        let alpha = CGFloat(UInt8(number & 0xff))/255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    convenience init(number: UInt32, alpha: CGFloat) {
        
        let red = CGFloat(UInt8(number >> 16))/255.0
        let green = CGFloat(UInt8(number >> 8 & 0xff))/255.0
        let blue = CGFloat(UInt8(number & 0xff))/255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func image(size: CGSize = CGSize.init(width: 1, height: 1), round: Bool = false) -> UIImage {
        
        let rect = CGRect.init(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        if round {
            context?.addPath(UIBezierPath.init(ovalIn: rect).cgPath)
            context?.clip()
        }
        context?.setFillColor(self.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    static var random: UIColor {
        
        let temp = arc4random() | 0x000000ff
        return UIColor.init(number: temp)
    }
}
