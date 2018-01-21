import AppKit
import CommandsCore

class InspectorViewController: NSViewController, NSTableViewDataSource {
    let applicationStateHandler = ApplicationStateHandler()
    var textViewPrinter: TextViewPrinter!
    let commandsController = CommandsController()
    @objc dynamic var isRunning = false
    let fileManager = FileManager.default
    var uiElements: [String] = []
    var parentCollection: [String] = []
    var filteredParentCollection: [String] = []
    var timer = Timer()
    var elementIndex: Int!
    var parentElementIndex: Int!
    var isParentView = false
    var retryCount = 0
    
    enum InspectorResources {
        static let temporaryScreenshotPath = "/tmp/screenshot_0.png"
        static let defaultGestureRecognizerAccessibilityLabel = "defaultImage"
        static let customGestureRecognizerAccessibilityLabel = "customImage"
        static let elementInspectorPath = "/tmp/get_all_elements_inspector.txt"
        static let cloneInfoPath = "/tmp/clone_info.txt"
    }

    
    @IBOutlet var startDeviceButton: NSButton!
    @IBOutlet var getElementsButton: NSButton!
    @IBOutlet var spinner: NSProgressIndicator!
    @IBOutlet var outputText: NSTextView!
    @IBOutlet var gestureRecognizer: NSClickGestureRecognizer!
    @IBOutlet var gestureRecognizableView: NSImageView!
    @IBOutlet var window: NSView!
    @IBOutlet var coordinatesMarker: NSImageView!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var elementTextField: NSTextField!
    @IBOutlet var localizedTextField: NSTextField!
    @IBOutlet var cleatBuffer: NSButton!
    @IBOutlet weak var cloneLabel: NSTextField!
    @IBOutlet weak var cloneButton: NSButton!
    
    func disableAllElements() {
        isRunning = true
        DispatchQueue.main.async {
            self.startDeviceButton.isEnabled = false
            self.getElementsButton.isEnabled = false
            self.spinner.startAnimation(self)
            self.gestureRecognizer.isEnabled = false
        }
    }

    func enableAllElements() {
        isRunning = false
        DispatchQueue.main.async {
            self.startDeviceButton.isEnabled = true
            self.getElementsButton.isEnabled = true
            self.spinner.stopAnimation(self)
            self.gestureRecognizer.isEnabled = true
        }
    }
    
    override func viewDidAppear() {
        outputText.backgroundColor = .darkAquamarine
        outputText.textColor = .lightGreen
        localizedTextField.textColor = .black
        elementTextField.textColor = .black
        outlineView.backgroundColor = .darkAquamarine
    }
    
    override func viewDidDisappear() {
        stopImageRefresh()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputText.alignment = NSTextAlignment.left
        gestureRecognizableView.addGestureRecognizer(gestureRecognizer)
        coordinatesMarker.isHidden = true
        getElementsButton.isEnabled = true
        startDeviceButton.isEnabled = true
        gestureRecognizer.isEnabled = true
        cloneButton.isHidden = true
        textViewPrinter = TextViewPrinter(textView: outputText)
    }

    @IBAction func doubleClickedItem(_ sender: NSOutlineView) {
        guard let item = sender.item(atRow: sender.clickedRow) as? String else { return }
        CommandExecutor(launchPath: Constants.FilePaths.Bash.flash ?? "", arguments: [item]).execute()
    }
    
    @IBAction func gestureRecognizer(_ sender: Any) {
        // Show dialog window if booted Simulator is incorrect (should be iPhone 6,7 or 8).
        DispatchQueue.global(qos: .background).async {
            guard let controller = self.storyboard?.instantiateController(withIdentifier: .wrongSimulator) as? NSViewController,
                !self.commandsController.isSimulatorCorrect else { return }
            DispatchQueue.main.async {
                self.presentViewControllerAsModalWindow(controller)
            }
        }
        
        if gestureRecognizableView.accessibilityLabel() == InspectorResources.defaultGestureRecognizerAccessibilityLabel {
            timer.invalidate()
            coordinatesMarker.isHidden = true
            syncScreen()
            getScreenProcs()
            timer = .scheduledTimer(timeInterval: 5.5, target: self, selector: #selector(getScreenProcsLoop), userInfo: nil, repeats: true);
        } else {
            let coordinates = gestureRecognizer.location(in: gestureRecognizableView)
            coordinatesMarker.isHidden = false
            coordinatesMarker.isHighlighted = true
            let convertedClickPoint = self.gestureRecognizableView.convert(coordinates, to: self.view)
            let markerFrame = NSRect(
                x: convertedClickPoint.x - coordinatesMarker.frame.size.width / 2 + 1,
                y: convertedClickPoint.y - coordinatesMarker.frame.size.height / 2 - 6,
                width: coordinatesMarker.frame.size.width,
                height: coordinatesMarker.frame.size.height)
            coordinatesMarker.frame = markerFrame
            uiElements = []
            parentCollection = []
            var parentTrigger = 0
            SharedElement.shared.coordinates = []
            SharedElement.shared.coordinates.append(coordinates.x.description)
            SharedElement.shared.coordinates.append(coordinates.y.description)
            let filePath = "/tmp/element_array.txt"
            try? fileManager.removeItem(atPath: filePath)
            disableAllElements()
            getElementsByOffset([coordinates.x.description, coordinates.y.description])

            let numberOfRetries = 990

            func handleURLLine(_ line: String) {
                if line == "==========" {
                    parentTrigger = 2
                    return
                }

                switch parentTrigger {
                case 0:
                    uiElements.append(line)
                case 2:
                    parentCollection.append(line)
                default:
                    return
                }
            }

            waitingForFile(withName: filePath, numberOfRetries: numberOfRetries) {
                
                guard let streamReader = StreamReader(path: filePath) else { return }
                defer { streamReader.close() }
                while let urlLine = streamReader.nextLine() {
                    handleURLLine(urlLine)
                }

                if self.uiElements.isEmpty {
                    sleep(1)
                    guard let streamReader = StreamReader(path: filePath) else { return }
                    defer { streamReader.close() }
                    while let urlLine = streamReader.nextLine() {
                        handleURLLine(urlLine)
                    }
                }

                self.getScreenProcs()
                self.enableAllElements()
                DispatchQueue.main.async {
                    self.outlineView.reloadData()
                }
            }
        }
    }

    @IBAction func clearBuffer(_ sender: Any) {
        outputText.string = ""
    }
    
    @IBAction func startDeviceButton(_ sender: Any) {
        timer.invalidate()
        coordinatesMarker.isHidden = true
        startDevice()
    }

    
    @IBAction func getElementsButton(_ sender: Any) {
        try? fileManager.removeItem(atPath: InspectorResources.elementInspectorPath)
        getElements()
        getElementsFromFile()
    }
    
    func fileIsNotEmpty(filePath: String) -> Bool {
        if !filePath.contains("txt") {
            return true
        } else {
            guard let streamReader = StreamReader(path: filePath) else { return false }
            defer { streamReader.close() }
            return streamReader.nextLine() != nil
        }
    }
    
    func waitingForFile(withName fileName: String, numberOfRetries: Int, enableSpinner: Bool = true, completion: @escaping () -> Void) {
        if enableSpinner {
            disableAllElements()
        }
        guard fileManager.fileExists(atPath: fileName) && fileIsNotEmpty(filePath: fileName) else {
            if numberOfRetries == retryCount {
                retryCount = 0
                DispatchQueue.main.async {
                    self.enableAllElements()
                    self.outputInTheMainTextView(string: "The command has failed after \(numberOfRetries) tries")
                }
                stopImageRefresh()
                return
            }
            DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
                self?.waitingForFile(withName: fileName, numberOfRetries: numberOfRetries, enableSpinner: enableSpinner, completion: completion)
            }
            retryCount += 1
            return
        }
        retryCount = 0
        completion()
    }
    
    func getElementsByOffset(_ arguments: [String]) {
        CommandExecutor(launchPath: Constants.FilePaths.Bash.elementsByOffset ?? "", arguments: arguments).execute()
    }
    
    func getElements() {
        let arguments: [String]
        if let filePath = applicationStateHandler.filePath {
            arguments = [filePath.absoluteString]
        } else {
            arguments = []
        }
        CommandExecutor(launchPath: Constants.FilePaths.Bash.elements ?? "", arguments: arguments).execute()
    }
    

    func outputInTheMainTextView(string: String) {
        outputText.string.append("\n\(string)")
    }
    
    func startDevice() {
        try? fileManager.removeItem(atPath: InspectorResources.temporaryScreenshotPath)
        
        if let launchPath = Constants.FilePaths.Bash.startDevice {
            let outputStream = CommandTextOutputStream()
            outputStream.textHandler = { text in
                guard !text.isEmpty else { return }
                DispatchQueue.main.async {
                    self.textViewPrinter.printToTextView(text)
                }
            }
            let arguments: [String]
            if let phoneUDID = applicationStateHandler.phoneUDID {
                arguments = [phoneUDID]
            } else {
                arguments = []
            }
            DispatchQueue.global(qos: .background).async {
                CommandExecutor(launchPath: launchPath, arguments: arguments, outputStream: outputStream).execute()
            }
        }

        let numberOfRetries = 9_999
        waitingForFile(withName: InspectorResources.temporaryScreenshotPath, numberOfRetries: numberOfRetries) {
            self.getScreenProcs()
            DispatchQueue.main.async {
                self.outputInTheMainTextView(string: "Simulator is ready to use")
            }
            self.enableAllElements()
        }
    }
    
    @objc func getScreenProcsLoop() {
        syncScreen()
        let numberOfRetries = 50
        waitingForFile(withName: InspectorResources.temporaryScreenshotPath, numberOfRetries: numberOfRetries, enableSpinner: false) {
            self.changeScreenshot()
            self.enableAllElements()
        }
    }
    
    func syncScreen() {
        try? fileManager.removeItem(atPath: InspectorResources.temporaryScreenshotPath)
        DispatchQueue.global(qos: .background).async {
            CommandExecutor(launchPath: Constants.FilePaths.Bash.screen ?? "", arguments: []).execute()
        }
    }
    
    func getScreenProcs() {
        let numberOfRetries = 40
        waitingForFile(withName: InspectorResources.temporaryScreenshotPath, numberOfRetries: numberOfRetries) {
            let imageURL = URL(fileURLWithPath: InspectorResources.temporaryScreenshotPath)
            let image = NSImage(contentsOfFile: imageURL.path)
            DispatchQueue.main.async {
                self.gestureRecognizableView.image = image
            }
            self.gestureRecognizableView.setAccessibilityLabel(InspectorResources.customGestureRecognizerAccessibilityLabel)
            try? self.fileManager.removeItem(atPath: InspectorResources.temporaryScreenshotPath)
            self.enableAllElements()
        }
    }
    
    func stopImageRefresh() {
        DispatchQueue.main.async {
            self.gestureRecognizableView.image = #imageLiteral(resourceName: "click_image.png")
        }
        gestureRecognizableView.setAccessibilityLabel(InspectorResources.defaultGestureRecognizerAccessibilityLabel)
        timer.invalidate()
    }
    
    func changeScreenshot() {
        let imageURL = URL(fileURLWithPath: InspectorResources.temporaryScreenshotPath)
        let image = NSImage(contentsOfFile: imageURL.path)
        DispatchQueue.main.async {
            self.gestureRecognizableView.image = image
        }
        try? fileManager.removeItem(atPath: InspectorResources.temporaryScreenshotPath)
    }
    
    func getElementsFromFile() {
        disableAllElements()
        var previousOutput = ""
        outputText.string = ""
        let numberOfRetries = 70
        waitingForFile(withName: InspectorResources.elementInspectorPath, numberOfRetries: numberOfRetries) {
            DispatchQueue.main.async {
                guard let streamReader = StreamReader(path: InspectorResources.elementInspectorPath) else { return }
                defer { streamReader.close() }
                while let urlLine = streamReader.nextLine() {

                    self.outputText.string = "\(previousOutput)\(urlLine)\n"

                    previousOutput = self.outputText.string
                }
            }
            self.enableAllElements()
            if self.outputText.string.isEmpty {
                self.outputInTheMainTextView(string: "The simulator seams to be not ready to use. Please use 'Start Simulator' button to start it properly".localized)
            }
        }
    }
}

extension InspectorViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        filteredParentCollection = []
        guard let item = item else {
            isParentView = false
            return uiElements.count
        }

        guard let elementItem = item as? String, let currentChildIndex = uiElements.index(of: elementItem) else { return 0 }
        isParentView = true

        var calculatedChildIndex = -1

        guard !parentCollection.isEmpty else { return 0 }

        parentCollection.forEach { parent in
            if parent == "\"separator\"" {
                calculatedChildIndex += 1
            } else if calculatedChildIndex == currentChildIndex {
                filteredParentCollection.append(parent)
            }
        }

        return filteredParentCollection.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if !isParentView {
            elementIndex = index
            return uiElements[index]
        } else {
            parentElementIndex = index
            return filteredParentCollection[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return !isParentView
    }
}

extension InspectorViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?

        if !isParentView {
            view = outlineView.makeView(withIdentifier: .feedCell, owner: self) as? NSTableCellView
            if let textField = view?.textField, let elementItem = item as? String {
                textField.textColor = NSColor.yellow
                textField.stringValue = elementItem
            }
        } else {
            view = outlineView.makeView(withIdentifier: .feedItemCell, owner: self) as? NSTableCellView
            if let textField = view?.textField, let elementItem = item as? String {
                textField.textColor = NSColor.cyan
                textField.stringValue = elementItem
            }
        }
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        cloneButton.isHidden = true
        cloneLabel.stringValue = ""
        guard let outlineView = notification.object as? NSOutlineView else { return }
        
        let selectedIndex = outlineView.selectedRow
        
        guard let feedItem = outlineView.item(atRow: selectedIndex) as? String else { return }
        localizedTextField.stringValue = ""
        elementTextField.stringValue = feedItem
        
        CommandExecutor(launchPath: Constants.FilePaths.Bash.checkDuplicates ?? "", arguments: [feedItem]).execute()
        waitingForFile(withName: InspectorResources.cloneInfoPath, numberOfRetries: 30, enableSpinner: false) {
            guard let streamReader = StreamReader(path: InspectorResources.cloneInfoPath) else { return }
            defer {
                streamReader.close()
                try? self.fileManager.removeItem(atPath: InspectorResources.cloneInfoPath)
            }
            guard let urlLine = streamReader.nextLine(), urlLine == "false" else { return }
            SharedElement.shared.stringValue = feedItem
            DispatchQueue.main.async {
                self.cloneButton.isHidden = false
                self.cloneLabel.stringValue = "The Element is not unique".localized
                self.cloneLabel.textColor = .red
            }
        }
    }
}
