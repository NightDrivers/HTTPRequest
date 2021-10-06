//
//  BKGeometryExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/6/6.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit

public extension CGRect {
    
    func insetBy(edgeInset: UIEdgeInsets) -> CGRect {
        
        return CGRect.init(
            x: self.origin.x + edgeInset.left,
            y: self.origin.y + edgeInset.top,
            width: self.size.width - edgeInset.left - edgeInset.right,
            height: self.size.height - edgeInset.top - edgeInset.bottom
        )
    }
}

public func + (lhs: CGRect, rhs: CGRect) -> CGRect {
    
    return CGRect.init(
        x: lhs.origin.x + rhs.origin.x,
        y: lhs.origin.y + rhs.origin.y,
        width: lhs.size.width + rhs.size.width,
        height: lhs.size.height + rhs.size.height
    )
}

public func - (lhs: CGRect, rhs: CGRect) -> CGRect {
    
    return CGRect.init(
        x: lhs.origin.x - rhs.origin.x,
        y: lhs.origin.y - rhs.origin.y,
        width: lhs.size.width - rhs.size.width,
        height: lhs.size.height - rhs.size.height
    )
}

public func * (rect: CGRect, scale: CGFloat) -> CGRect {
    
    return CGRect.init(
        x: rect.origin.x*scale,
        y: rect.origin.y*scale,
        width: rect.width*scale,
        height: rect.height*scale
    )
}

public func / (rect: CGRect, divided: CGFloat) -> CGRect {
    
    return CGRect.init(
        x: rect.origin.x/divided,
        y: rect.origin.y/divided,
        width: rect.width/divided,
        height: rect.height/divided
    )
}

public func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    
    return CGSize.init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

public func - (lhs: CGSize, rhs: CGSize) -> CGSize {
    
    return CGSize.init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

public func * (size: CGSize, scale: CGFloat) -> CGSize {
    
    return CGSize.init(width: size.width*scale, height: size.height*scale)
}

public func / (size: CGSize, divided: CGFloat) -> CGSize {
    
    return CGSize.init(width: size.width/divided, height: size.height/divided)
}

public func * (inset: UIEdgeInsets, scale: CGFloat) -> UIEdgeInsets {
    
    return UIEdgeInsets.init(
        top: inset.top*scale,
        left: inset.left*scale,
        bottom: inset.bottom*scale,
        right: inset.right*scale
    )
}

public func / (inset: UIEdgeInsets, divided: CGFloat) -> UIEdgeInsets {
    
    return UIEdgeInsets.init(
        top: inset.top/divided,
        left: inset.left/divided,
        bottom: inset.bottom/divided,
        right: inset.right/divided
    )
}

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    
    return CGPoint.init(x: lhs.x+rhs.x, y: lhs.y+rhs.y)
}

public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    
    return CGPoint.init(x: lhs.x-rhs.x, y: lhs.y-rhs.y)
}

public func / (point: CGPoint, divided: CGFloat) -> CGPoint {
    
    return CGPoint.init(x: point.x/divided, y: point.y/divided)
}

public func * (point: CGPoint, scale: CGFloat) -> CGPoint {
    
    return CGPoint.init(x: point.x*scale, y: point.y*scale)
}

public extension CGSize {
    
    var ratio: CGFloat { width / height }
    
    func asPoint() -> CGPoint { CGPoint.init(x: width, y: height) }
}

public extension CGPoint {
    
    func asSize() -> CGSize { CGSize.init(width: x, height: y) }
}

public extension CGAffineTransform {
    
    /// 要求变换矩阵不包含缩放分量
    var rotate: CGFloat { return atan2(b, a) }
    
    /// 要求变换矩阵不包含旋转分量
    var scaleX: CGFloat { return sqrt(a*a+c*c) }
    
    var scaleY: CGFloat { return sqrt(b*b+d*d) }
    
    var translateX: CGFloat { return tx }
    
    var translateY: CGFloat { return ty }
}
