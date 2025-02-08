//
//  IconGenerator.swift
//  AppIconBox
//
//  Created by 孙翔宇 on 05/07/2019.
//  Copyright © 2019 孙翔宇. All rights reserved.
//

import Cocoa


class MacIconGenerator: IconGenerator {
    let image: NSImage
    private(set) var icons: [Icon]
    let iconsDirURL: URL
    
    init(marktingImage: NSImage) throws {
        image = marktingImage
        
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Icons")
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        iconsDirURL = destinationURL
        
        var app = try MacIconGenerator.generateIconSets(jsonFile: "AppSample")
        let watch = try MacIconGenerator.generateIconSets(jsonFile: "WatchSample")
        let mac = try MacIconGenerator.generateIconSets(jsonFile: "MacSample")

        
        app.append(contentsOf: watch)
        app.append(contentsOf: mac)
        
        icons = app
    }
    
    static func generateIconSets(jsonFile: String) throws -> [Icon] {
        guard let appJson = Bundle.main.url(forResource: jsonFile, withExtension: "json") else {
            throw IconGeneratorError.invalidConfiguration
        }
        let data = try Data(contentsOf: appJson)
        let decoder = JSONDecoder()
        return try decoder.decode([Icon].self, from: data)
    }

    func write(icon: Icon, to url: URL) throws {
        
        let outpuImage = NSImage(size: icon.pixelSize, flipped: false) { [unowned self] (rect) -> Bool in
            
            let delta = rect.width - rect.height
            
            if delta == 0 {
                self.image.draw(in: rect)
            } else {
                var drawRect = rect
                if delta > 0 {
                    drawRect.origin.x = delta * 0.5
                    drawRect.size.width = rect.height
                } else {
                    drawRect.origin.y = abs(delta) * 0.5
                    drawRect.size.height = rect.width
                }
                self.image.draw(in: drawRect)
            }
            return true
        }
        
        guard let tiffData = outpuImage.tiffRepresentation else { return  }
        let bitmapImageRep = NSBitmapImageRep(data: tiffData)
        let data = bitmapImageRep?.representation(using: .png, properties: [:])
        
        let fileURL = url.appendingPathComponent("\(icon.debugDescription).png")
        try data?.write(to: fileURL)
    }
}
