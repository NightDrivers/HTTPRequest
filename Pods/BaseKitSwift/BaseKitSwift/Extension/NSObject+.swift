//
//  NSObject+.swift
//  BaseKitSwift
//
//  Created by ldc on 2021/7/16.
//  Copyright © 2021 Xiamen Hanin. All rights reserved.
//

import Foundation

public extension NSObject {
    
    static var className: String { String.init(describing: self) }
}
