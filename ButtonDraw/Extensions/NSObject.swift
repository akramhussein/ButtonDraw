//
//  NSObject.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 18/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import Foundation

public extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}
