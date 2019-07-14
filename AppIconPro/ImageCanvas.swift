//
//  ImageCanvas.swift
//  AppIconBox
//
//  Created by 孙翔宇 on 05/07/2019.
//  Copyright © 2019 孙翔宇. All rights reserved.
//

import Cocoa

/// Delegate for handling dragging events
@objc protocol ImageCanvasDelegate: AnyObject {
    func draggingEntered(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> NSDragOperation
    func performDragOperation(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> Bool
    func pasteboardWriter(forImageCanvas imageCanvas: ImageCanvas) -> NSPasteboardWriting
}

/// View holding one base image and many user-editable text labels
class ImageCanvas: NSView, NSDraggingSource {
    
    func iconsGenerator() throws -> MacIconGenerator {
        guard let image = self.image else {
            throw IconGeneratorError.invalidConfiguration
        }
        return try MacIconGenerator(marktingImage: image)
    }
    
    
    var isHighlighted: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            imageView.isEnabled = !isLoading
            progressIndicator.isHidden = !isLoading
            if isLoading {
                progressIndicator.startAnimation(nil)
            } else {
                progressIndicator.stopAnimation(nil)
            }
        }
    }
    
    var image: NSImage? {
        set {
            imageView.image = newValue
            if let imageRep = newValue?.representations.first {
                imagePixelSize = CGSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh)
            }
            window?.title = imageDescription
            isLoading = false
            needsLayout = true
        }
        get {
            return imageView.image
        }
    }
    
    private var imageDescription: String {
        return (image != nil) ? "\(Int(imagePixelSize.width)) × \(Int(imagePixelSize.height))" : "..."
    }
    
    var draggingImage: NSImage {
        let targetRect = overlay.frame
        let image = NSImage(size: targetRect.size)
        if let imageRep = bitmapImageRepForCachingDisplay(in: targetRect) {
            cacheDisplay(in: targetRect, to: imageRep)
            image.addRepresentation(imageRep)
        }
        return image
    }
    
    
    private let dragThreshold: CGFloat = 3.0
    private var dragOriginOffset = CGPoint.zero
    private var imagePixelSize = CGSize.zero
    
    @IBOutlet weak var delegate: ImageCanvasDelegate?
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var imageView: NSImageView!
    
    private var overlay: NSView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.unregisterDraggedTypes()
        progressIndicator.isHidden = true // explicitly hiding the indicator in order not to catch mouse events
        
        overlay = NSView()
        addSubview(overlay)
    }

    
    private func rectForDrawingImage(with imageSize: CGSize, scaling: NSImageScaling) -> CGRect {
        var drawingRect = CGRect(origin: .zero, size: imageSize)
        let containerRect = bounds
        guard imageSize.width > 0 && imageSize.height > 0 else {
            return drawingRect
        }
        
        func scaledSizeToFitFrame() -> CGSize {
            var scaledSize = CGSize.zero
            let horizontalScale = containerRect.width / imageSize.width
            let verticalScale = containerRect.height / imageSize.height
            let minimumScale = min(horizontalScale, verticalScale)
            scaledSize.width = imageSize.width * minimumScale
            scaledSize.height = imageSize.height * minimumScale
            return scaledSize
        }
        
        switch scaling {
        case .scaleProportionallyDown:
            if imageSize.width > containerRect.width || imageSize.height > containerRect.height {
                drawingRect.size = scaledSizeToFitFrame()
            }
        case .scaleAxesIndependently:
            drawingRect.size = containerRect.size
        case .scaleProportionallyUpOrDown:
            if imageSize.width > 0.0 && imageSize.height > 0.0 {
                drawingRect.size = scaledSizeToFitFrame()
            }
        case .scaleNone:
            break
        @unknown default:
            fatalError()
        }
        
        drawingRect.origin.x = containerRect.minX + (containerRect.width - drawingRect.width) * 0.5
        drawingRect.origin.y = containerRect.minY + (containerRect.height - drawingRect.height) * 0.5
        
        return drawingRect
    }

    // MARK: - NSView
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        let eventMask: NSEvent.EventTypeMask = [.leftMouseUp, .leftMouseDragged]
        let timeout = NSEvent.foreverDuration
        
        if image != nil {
            // drag the flattened image
            window?.trackEvents(matching: eventMask, timeout: timeout, mode: .eventTracking, handler: { (event, stop) in
                guard let event = event else { return }
                
                if event.type == .leftMouseUp {
                    stop.pointee = true
                } else {
                    let movedLocation = convert(event.locationInWindow, from: nil)
                    if abs(movedLocation.x - location.x) > dragThreshold || abs(movedLocation.y - location.y) > dragThreshold {
                        stop.pointee = true
                        if let delegate = delegate {
                            let draggingItem = NSDraggingItem(pasteboardWriter: delegate.pasteboardWriter(forImageCanvas: self))
                            draggingItem.setDraggingFrame(overlay.frame, contents: draggingImage)
                            beginDraggingSession(with: [draggingItem], event: event, source: self)
                        }
                    }
                }
            })
        }
    }
    
    override func layout() {
        super.layout()
        
        let imageSize = image?.size ?? .zero
        overlay.frame = rectForDrawingImage(with: imageSize, scaling: imageView.imageScaling)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isHighlighted {
            NSGraphicsContext.saveGraphicsState()
            NSFocusRingPlacement.only.set()
            bounds.insetBy(dx: 2, dy: 2).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    
    // MARK: - NSDraggingSource
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return (context == .outsideApplication) ? [.copy] : []
    }
    
    // MARK: - NSDraggingDestination
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        var result: NSDragOperation = []
        if let delegate = delegate {
            result = delegate.draggingEntered(forImageCanvas: self, sender: sender)
            isHighlighted = (result != [])
        }
        return result
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return delegate?.performDragOperation(forImageCanvas: self, sender: sender) ?? true
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHighlighted = false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        isHighlighted = false
    }
    
}
