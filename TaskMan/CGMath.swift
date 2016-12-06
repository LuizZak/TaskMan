//
//  CGMath.swift
//  TaskMan
//
//  Created by Luiz Fernando Silva on 05/12/16.
//  Copyright © 2016 Luiz Fernando Silva. All rights reserved.
//

import Cocoa

extension NSPoint {
    
    /// Returns the magnitude for this point
    var magnitude: CGFloat {
        return sqrt((x * x) + (y * y))
    }
    
    /// Subtracts two points
    static func -(lhs: NSPoint, rhs: NSPoint) -> NSPoint {
        return NSPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
