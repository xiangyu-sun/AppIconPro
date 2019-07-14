//
//  Icon.swift
//  AppIconBox
//
//  Created by 孙翔宇 on 04/07/2019.
//  Copyright © 2019 孙翔宇. All rights reserved.
//

import Foundation

public struct Icon: Decodable, CustomDebugStringConvertible {
    let size: String
    public let idiom: String
    let scale: String
    let role: String?
    let subtype: String?
    
    public var scaleFactor: Double {
        guard let scaleChar = scale.first, let scale = Double(String(scaleChar)) else {
            return 1
        }
        return scale
    }
    
    public var pixelSize: CGSize {
        guard let width = size.components(separatedBy: "x").first, let widthValue = Double(width) else {
            return CGSize.zero
        }
        
        return CGSize(width: widthValue * scaleFactor, height: widthValue * scaleFactor)
    }
    
    public var debugDescription: String {
        let sufix = scaleFactor == 1 ? "" : "@\(scale)"
        return "\(size)\(sufix)"
    }
}
