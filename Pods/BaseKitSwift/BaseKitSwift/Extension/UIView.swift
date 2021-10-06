//
//  BKViewExtension.swift
//  BaseKit
//
//  Created by ldc on 2018/5/23.
//  Copyright © 2018年 Xiamen Hanin. All rights reserved.
//

import UIKit

public extension UIView {
    
    var width: CGFloat {
        
        set {
            bounds.size.width = newValue
        }
        
        get {
            return bounds.width
        }
    }
    
    var height: CGFloat {
        
        set {
            bounds.size.height = newValue
        }
        
        get {
            return bounds.height
        }
    }
    
    var viewController: UIViewController? {
        
        var result: UIViewController?
        var responder: UIResponder? = self
        while true  {
            if let _ = responder {
                if let temp = responder as? UIViewController {
                    result = temp
                    break
                }else {
                    responder = responder?.next
                }
            }else {
                break
            }
        }
        return result
    }
}

public extension UIView {
    
    private static var swizzled = false
    
    private struct Key {
        static var TouchEdgeInsetKey = 0
    }
    //修改手势触发范围
    var touchEdgeInset: UIEdgeInsets? {
        
        get {
            return objc_getAssociatedObject(self, &Key.TouchEdgeInsetKey) as? UIEdgeInsets
        }
        
        set {
            objc_setAssociatedObject(self, &Key.TouchEdgeInsetKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    static func swizzlePointInsideMethod() {
        
        guard Thread.isMainThread else { return }
        if swizzled { return }
        
        swizzled = true
        
        if let origin = class_getInstanceMethod(self, #selector(point(inside:with:))),
            let new = class_getInstanceMethod(self, #selector(bk_point(inside:with:))) {
            method_exchangeImplementations(origin, new)
        }
    }
    
    @objc func bk_point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        if let inset = touchEdgeInset {
            let rect = bounds.insetBy(edgeInset: inset)
            return rect.contains(point)
        }else {
            return self.bk_point(inside: point, with: event)
        }
    }
}

public extension UIImageView {
    
    convenience init?(gifPath: String) {
        
        let url = URL.init(fileURLWithPath: gifPath)
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
            
            self.init(frame: .zero)
            let count = CGImageSourceGetCount(imageSource)
            if count <= 1 {
                if let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                    let image = UIImage.init(cgImage: imageRef)
                    self.image = image
                }
            }else {
                var images = [UIImage]()
                for i in 0..<count {
                    if let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                        images.append(UIImage.init(cgImage: imageRef))
                    }
                }
                self.image = images[0]
                self.animationImages = images
                self.animationDuration = TimeInterval(count)/30.0
            }
        }else {
            return nil
        }
    }
}

public extension UIView {
    
    class func fromNib(_ bundle : Bundle = .main) -> Self {
        
        guard let nib = bundle.loadNibNamed(className, owner: nil, options: nil) else {
            return Self()
        }
        guard let instantiate = nib.first as? Self else {
            return Self()
        }
        return instantiate
    }
    
    static func loadNib(_ bundle : Bundle = .main) -> UINib? {
        
        let hasNib: Bool = bundle.path(forResource: className, ofType: "nib") != nil
        guard hasNib else {
            return nil
        }
        return UINib(nibName: "\(self)", bundle: bundle)
    }
}

extension UITableView {
    
    public func bk_registerClassForCell(_ cellClass: NSObject.Type) -> Void {
        register(cellClass, forCellReuseIdentifier: cellClass.className)
    }
    
    public func bk_registerNibForCell(_ cellClass: NSObject.Type, bundle: Bundle? = nil) -> Void {
        register(UINib.init(nibName: cellClass.className, bundle: bundle), forCellReuseIdentifier: cellClass.className)
    }
    
    public func bk_registerClassForHeaderFooterView(_ cellClass: NSObject.Type) -> Void {
        register(cellClass, forHeaderFooterViewReuseIdentifier: cellClass.className)
    }
    
    public func bk_registerNibForHeaderFooterView(_ cellClass: NSObject.Type, bundle: Bundle? = nil) -> Void {
        register(UINib.init(nibName: cellClass.className, bundle: bundle), forHeaderFooterViewReuseIdentifier: cellClass.className)
    }
}

public extension UITableViewCell {
    
    class func bk_dequeueReusableCell(_ tableView: UITableView, for indexPath: IndexPath) -> Self {
        
        return tableView.dequeueReusableCell(withIdentifier: className, for: indexPath) as! Self
    }
}

public extension UITableViewHeaderFooterView {
    
    class func bk_dequeueReusableCell(_ tableView: UITableView, for indexPath: IndexPath) -> Self {
        
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: className) as! Self
    }
}

extension UICollectionView {
    
    public func bk_registerClassForCell(_ cellClass: NSObject.Type) -> Void {
        register(cellClass, forCellWithReuseIdentifier: cellClass.className)
    }
    
    public func bk_registerNibForCell(_ cellClass: NSObject.Type, bundle: Bundle? = nil) -> Void {
        register(UINib.init(nibName: cellClass.className, bundle: bundle), forCellWithReuseIdentifier: cellClass.className)
    }
    
    public func bk_registerClassForSupplementaryView(_ cellClass: NSObject.Type, kind: String) -> Void {
        register(cellClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: cellClass.className)
    }
    
    public func bk_registerNibForSupplementaryView(_ cellClass: NSObject.Type, kind: String, bundle: Bundle? = nil) -> Void {
        register(UINib.init(nibName: cellClass.className, bundle: bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: cellClass.className)
    }
}

public extension UICollectionViewCell {
    
    class func bk_dequeueReusableCell(_ collectionView: UICollectionView, for indexPath: IndexPath) -> Self {
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: className, for: indexPath) as! Self
    }
}

public extension UICollectionReusableView {
    
    class func bk_dequeueReusableSupplementaryView(_ collectionView: UICollectionView, of kind: String, for indexPath: IndexPath) -> Self {
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: className, for: indexPath) as! Self
    }
}
