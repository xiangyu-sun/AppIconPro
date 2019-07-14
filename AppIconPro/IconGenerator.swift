//
//  File.swift
//  
//
//  Created by 孙翔宇 on 05/07/2019.
//

import Foundation

public enum IconGeneratorError: Error {
    case invalidConfiguration
}

public protocol IconGenerator {
    var icons: [Icon] { get }
    var iconsDirURL: URL { get }
    func generateIcons() throws
    func populateIconStructure() throws -> [String : [Icon]]
    func write(icon: Icon, to url: URL) throws
}

public extension IconGenerator {
    func populateIconStructure() throws -> [String : [Icon]]{
        return icons.reduce(into: [:]) { (result, icon) in
            if result[icon.idiom] == nil {
                result[icon.idiom] = []
            }
            result[icon.idiom]?.append(icon)
        }
    }
    
    func generateIcons() throws {
        
        try FileManager.default.removeItem(at: iconsDirURL)
        let outputStructure = try populateIconStructure()
        try outputStructure.forEach { (idiom, icons) in
            let url = self.iconsDirURL.appendingPathComponent(idiom)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            try icons.forEach { (icon) in
                try write(icon: icon, to: url)
            }
        }
    }
}
