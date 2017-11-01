//
//  Sticker.swift
//  ButtonDraw
//
//  Created by Akram Hussein on 17/09/2017.
//  Copyright © 2017 Akram Hussein. All rights reserved.
//

import UIKit

public enum Sticker: String {
    case ayala_a
    case caira_c
    case star
    case ayala_name
    case caira_name
    case flower
    case eye_left
    case eye_right
    case mouth1
    case eye_lash_left
    case eye_lash_right
    case mouth2
    
    public static let all: [Sticker] = [
        .ayala_a,
        .caira_c,
        .star,
        .ayala_name,
        .caira_name,
        .mouth1,
        .eye_left,
        .eye_right,
        .mouth2,
        .eye_lash_left,
        .eye_lash_right,
        .flower,
    ]
    
    private var url: URL {
        return Bundle.main.url(forResource: self.rawValue, withExtension: "json")!
    }

    public var image: UIImage? {
        return UIImage(named: self.rawValue)?.withRenderingMode(.alwaysTemplate)
    }
    
    public var paths: [Int: [(Double, Double)]] {
        var d = [Int: [(Double, Double)]]()
        
        do {
            let jsonData = try Data(contentsOf: self.url, options: .mappedIfSafe)
            
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: [[Double]]] else {
                return d
            }
            
            json.forEach({ (key, value) in
                guard let kInt = Int(key) else { return }
                
                var tuples = [(Double, Double)]()
                
                value.forEach{ tuples.append(($0[0], $0[1])) }
                
                d[kInt] = tuples
            })
            
            return d
        } catch {
            return d
        }

    }

}
