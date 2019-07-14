import Cocoa

class ImageCanvasController: NSViewController, NSFilePromiseProviderDelegate, ImageCanvasDelegate {
    
    enum RuntimeError: Error {
        case unavailableSnapshot
    }

    /// main view
    @IBOutlet weak var imageCanvas: ImageCanvas!
    
    /// placeholder label which is displayed before any image has been dropped onto the app
    @IBOutlet weak var placeholderLabel: NSTextField!


    /// queue used for reading and writing file promises
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
    /// directory URL used for accepting file promises
    private lazy var destinationURL: URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()
    
    /// updates the canvas with a given image
    private func handleImage(_ image: NSImage?) {
        imageCanvas.image = image
        placeholderLabel.isHidden = (image != nil)
    }

    /// updates the canvas with a given image file
    private func handleFile(at url: URL) {
        let image = NSImage(contentsOf: url)
        
        OperationQueue.main.addOperation {
            self.handleImage(image)
        }
    }
    
    /// displays an error
    private func handleError(_ error: Error) {
        OperationQueue.main.addOperation {
            if let window = self.view.window {
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                self.presentError(error)
            }
        }
    }
    
    /// displays a progress indicator
    private func prepareForUpdate() {
        imageCanvas.isLoading = true
        placeholderLabel.isHidden = true
    }

    // MARK: - NSViewController
    /// - Tag: RegisterPromiseReceiver
    override func viewDidLoad() {
        super.viewDidLoad()
        view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    // MARK: - ImageCanvasDelegate
    
    func draggingEntered(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask.intersection([.copy])
    }
    
    func performDragOperation(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> Bool {
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self
        ]

        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: [ kUTTypeImage ]
        ]
        /// - Tag: HandleFilePromises
        sender.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { (draggingItem, _, _) in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                self.prepareForUpdate()
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, options: [:],
                                                         operationQueue: self.workQueue) { (fileURL, error) in
                    if let error = error {
                        self.handleError(error)
                    } else {
                        self.handleFile(at: fileURL)
                    }
                }
            case let fileURL as URL:
                self.handleFile(at: fileURL)
            default: break
            }
        }
        
        return true
    }
    
    func pasteboardWriter(forImageCanvas imageCanvas: ImageCanvas) -> NSPasteboardWriting {
        let provider = NSFilePromiseProvider(fileType: kUTTypeDirectory as String, delegate: self)
        do {
            provider.userInfo = try imageCanvas.iconsGenerator()
        } catch {
            handleError(error)
        }
        return provider
    }
    
    // MARK: - NSFilePromiseProviderDelegate
    
    /// - Tag: ProvideFileName
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        return "Icons"
    }
    
    /// - Tag: ProvideOperationQueue
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return workQueue
    }
    
    /// - Tag: PerformFileWriting
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        do {
            if let generator = filePromiseProvider.userInfo as? MacIconGenerator {
                try generator.generateIcons()
                try FileManager.default.copyItem(at: generator.iconsDirURL, to: url)
            } else {
                throw RuntimeError.unavailableSnapshot
            }
            completionHandler(nil)
        } catch let error {
            completionHandler(error)
        }
    }
}
