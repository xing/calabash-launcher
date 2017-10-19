import Cocoa
import Foundation
import AppKit
import CommandsCore

class InspectorViewController: NSViewController, NSTableViewDataSource {
    let commands = CommandsCore.CommandExecutor()
    var runDeviceTask:Process!
    var runDeviceTask1:Process!
    var runDeviceTask2:Process!
    var runDeviceTask3:Process!
    var buildTaskNew12:Process!
    var buildTaskNew34:Process!
    var buildTaskNew558:Process!
    var buildTaskNew:Process!
    @objc dynamic var isRunning = false
    var outputPipe:Pipe!
    var pathToCalabashFolder: String = ""
    let defaults = UserDefaults.standard
    let env = ProcessInfo.processInfo.environment as [String: String]
    let fileManager = FileManager.default
    var uiElements: [String] = []
    var parentCollection: [String] = []
    var filteredParentCollection: [String] = []
    var timer = Timer()
    var elementIndex:Int!
    var parentElementIndex:Int!
    var isParentView:Bool = false
    var retryCount:Int = 0
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        calabashIsRunning()

        self.getHomeDirectoryPath()
        gestureRecognizableView.addGestureRecognizer(gestureRecognizer)
        coordinatesMarker.isHidden = true
        self.getElementsButton.isEnabled = true
        self.startDeviceButton.isEnabled = true
        self.gestureRecognizer.isEnabled = true
        self.cloneButton.isHidden = true
    }

    func setUserDefaultsListener(){
        UserDefaults.standard.addObserver(self, forKeyPath: "FilePath", options: .new, context: nil)
    }
    
   override func observeValue(forKeyPath: String?, of: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
       if forKeyPath == "FilePath" {
            self.getHomeDirectoryPath()
            self.getElementsButton.isEnabled = true
            self.startDeviceButton.isEnabled = true
            self.gestureRecognizer.isEnabled = true
        }
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "FilePath")
    }
    
    
    @IBAction func doubleClickedItem(_ sender: NSOutlineView) {
        if let item = sender.item(atRow: sender.clickedRow) as? String {
            commands.executeCommand(at: Constants.FilePaths.Bash.flash ?? "", arguments: [item])
        }
    }
    
    @IBAction func gestureRecognizer(_ sender: Any) {
        if gestureRecognizableView.accessibilityLabel() == "defaultImage" {
            timer.invalidate()
            coordinatesMarker.isHidden = true
            syncScreen()
            getScreenProcs()
            timer = .scheduledTimer(timeInterval: 5.5, target: self, selector: #selector(self.getScreenProcsLoop), userInfo: nil, repeats: true);
        } else {
            let coordinates = gestureRecognizer.location(in: gestureRecognizableView)
            self.coordinatesMarker.isHidden = false
            self.coordinatesMarker.isHighlighted = true
            let convertedClickPoint = self.gestureRecognizableView.convert(coordinates, to: self.view)
            self.coordinatesMarker.frame = NSRect(x: convertedClickPoint.x - self.coordinatesMarker.frame.size.width/2 + 1, y: convertedClickPoint.y - self.coordinatesMarker.frame.size.height/2 - 6, width: self.coordinatesMarker.frame.size.width, height: self.coordinatesMarker.frame.size.height)
            var arguments: [String] = []
            uiElements = []
            parentCollection = []
            var parent_trigger = 0

            arguments.append(coordinates.x.description)
            arguments.append(coordinates.y.description)
            SharedElement.shared.coordinates = []
            SharedElement.shared.coordinates.append(coordinates.x.description)
            SharedElement.shared.coordinates.append(coordinates.y.description)
            do {
                try fileManager.removeItem(atPath: "/tmp/element_array.txt")
            } catch { }

            self.disableAllElements()
            getElementsByOffset(arguments)

            let filePath = "/tmp/element_array.txt"

            waitingForFile(fileName: "/tmp/element_array.txt", numberOfRetries: 990) {

                if let aStreamReader = StreamReader(path: filePath) {
                    defer {
                        aStreamReader.close()
                    }
                    while let url_line = aStreamReader.nextLine() {

                        if url_line == "==========" {
                            parent_trigger = 2
                            continue
                        }

                        if parent_trigger == 0 {
                            self.uiElements.append(url_line)
                        } else if parent_trigger == 2 {
                            self.parentCollection.append(url_line)
                        }
                    }

                    if self.uiElements == [] {
                        sleep(1)
                        if let aStreamReader = StreamReader(path: filePath) {
                            defer {
                                aStreamReader.close()
                            }
                            while let url_line = aStreamReader.nextLine() {

                                if url_line == "==========" {
                                    parent_trigger = 2
                                    continue
                                }

                                if parent_trigger == 0 {
                                    self.uiElements.append(url_line)
                                } else if parent_trigger == 2 {
                                    self.parentCollection.append(url_line)
                                }
                            }
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
        
        do {
            try fileManager.removeItem(atPath: "/tmp/get_all_elements_inspector.txt")
        } catch _ as NSError {
            //print(error.debugDescription)
        }
        
        getElements()
        getElementsFromFile()
    }
    
    func calabashIsRunning() {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        
        taskQueueNew.sync {
            
            let path = Constants.FilePaths.Bash.sendToIRB
            self.buildTaskNew558 = Process()
            self.buildTaskNew558.launchPath = path
            
            var arguments:[String] = []
            arguments.append("healthcheck")
            
            self.buildTaskNew558.arguments = arguments
            
            self.buildTaskNew558.launch()
            self.buildTaskNew558.waitUntilExit()
        }
        
        let filePath = "/tmp/is_running.txt"
        self.waitingForFile(fileName: filePath, numberOfRetries: 10, enableSpinner: false) {
            if let aStreamReader = StreamReader(path: filePath) {
                defer {
                    aStreamReader.close()
                }
                if aStreamReader.nextLine() == "false" {
                    self.disableAllElements()
                } else {
                    self.enableAllElements()
                }
            }
        }

    }
    
    func fileIsNotEmpty(filePath: String) -> Bool {
        if filePath.range(of: "txt") == nil {
            return true
        } else {
            var found = false
            if let aStreamReader = StreamReader(path: filePath) {
                defer {
                    aStreamReader.close()
                }
                if aStreamReader.nextLine() != nil {
                    found = true
                }
            }

            return found
        }
    }
    
    func waitingForFile(fileName: String, numberOfRetries: Int, enableSpinner:Bool = true,completion: @escaping () -> Void) {
        if enableSpinner {
            self.disableAllElements()
        }
        guard FileManager.default.fileExists(atPath: fileName) && fileIsNotEmpty(filePath: fileName)
                else {
                    if numberOfRetries == retryCount {
                        retryCount = 0
                        DispatchQueue.main.async {
                        self.enableAllElements()
                        self.outputInTheMainTextView(string: "The command has failed after \(numberOfRetries) tries")
                        }
                        return
                    }
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 0.1,
                                                                                          execute: { [weak self] in
                                                                                            self?.waitingForFile(fileName: fileName, numberOfRetries: numberOfRetries, enableSpinner: enableSpinner, completion: completion)
                    })
                    retryCount += 1
                    return
            }
        retryCount = 0
        completion()
        }
    
    
    func getHomeDirectoryPath() {
        if (defaults.url(forKey: "FilePath") != nil) {
            let path_string = "\(defaults.url(forKey: "FilePath")!)"
            self.pathToCalabashFolder = (env["HOME"]! + "/" + path_string
                .replacingOccurrences(of: env["HOME"]!, with: ""))
                .replacingOccurrences(of: "~/", with: "")
                .replacingOccurrences(of: "file://", with: "")
        } else {
            setUserDefaultsListener()
        }
    }

    func getElementsByOffset(_ arguments:[String]) {
        
        let taskQueue6 = DispatchQueue.global(qos: .background)
        
        taskQueue6.async {
            
            let path = Constants.FilePaths.Bash.elementsByOffset
            self.runDeviceTask = Process()
            self.runDeviceTask.launchPath = path
            
            self.runDeviceTask.arguments = arguments
            
            self.runDeviceTask.launch()
        }
    }
    
    
    func getElements() {
        let taskQueue7 = DispatchQueue.global(qos: .background)
        
        taskQueue7.async {
            
            let path = Constants.FilePaths.Bash.elements
            self.runDeviceTask1 = Process()
            self.runDeviceTask1.launchPath = path
            var arguments:[String] = []
            arguments.append(self.pathToCalabashFolder)
            self.runDeviceTask1.arguments = arguments
            self.runDeviceTask1.launch()
        }
    }
    

    func outputInTheMainTextView(string: String) {
        let previousOutput = self.outputText.string
        self.outputText.string = previousOutput + "\n" + string
    }
    
    func startDevice() {
        do {
            try fileManager.removeItem(atPath: "/tmp/screenshot_0.png")
        } catch { }
        
        let taskQueue8 = DispatchQueue.global(qos: .background)
        
        taskQueue8.async {
            
            let path = Constants.FilePaths.Bash.startDevice
            self.runDeviceTask2 = Process()
            self.runDeviceTask2.launchPath = path
            var arguments:[String] = []
            arguments.append(self.pathToCalabashFolder)
            
            self.runDeviceTask2.arguments = arguments
            
            
            self.captureStandardOutputAndRouteToTextView(self.runDeviceTask2)
            self.runDeviceTask2.launch()
            self.runDeviceTask2.waitUntilExit()
        }
        
        self.waitingForFile(fileName: "/tmp/screenshot_0.png", numberOfRetries: 9999) {
            

        self.getScreenProcs()
            DispatchQueue.main.async {
                self.outputInTheMainTextView(string: "Simulator is ready to use")
            }
            self.enableAllElements()
        }
        
    }
    
    func captureStandardOutputAndRouteToTextView(_ task:Process) {

        outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { notification in
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: .utf8) ?? ""
            
            DispatchQueue.main.async {
                let previousOutput = self.outputText.string

                if !outputString.isEmpty {
                    
                    let nextOutput = previousOutput + "\n" + outputString
                    self.outputText.string = nextOutput
                    
                    let range = NSRange(location: nextOutput.count, length: 0)
                    self.outputText.scrollRangeToVisible(range)
                }
            }
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    
    @objc func getScreenProcsLoop() {
        syncScreen()
        waitingForFile(fileName: "/tmp/screenshot_0.png", numberOfRetries: 50, enableSpinner: false) {
            self.changeScreenshot()
            self.enableAllElements()
        }
    }
    
    func syncScreen() {
        try? fileManager.removeItem(atPath: "/tmp/screenshot_0.png")
        commands.executeCommand(at: Constants.FilePaths.Bash.screen ?? "", arguments: [])
    }
    
    func getScreenProcs() {
        self.waitingForFile(fileName: "/tmp/screenshot_0.png", numberOfRetries: 40) {
            let imageURL = URL(fileURLWithPath: "/tmp/screenshot_0.png")
            let image = NSImage(contentsOfFile: imageURL.path)
            DispatchQueue.main.async {
                self.gestureRecognizableView.image = image
            }
            self.gestureRecognizableView.setAccessibilityLabel("customImage")
            try? self.fileManager.removeItem(atPath: "/tmp/screenshot_0.png")
            self.enableAllElements()
        }
    }
    
    func changeScreenshot() {
        let imageURL = URL(fileURLWithPath: "/tmp/screenshot_0.png")
        let image = NSImage(contentsOfFile: imageURL.path)
        DispatchQueue.main.async {
            self.gestureRecognizableView.image = image
        }
        
        do {
            try fileManager.removeItem(atPath: "/tmp/screenshot_0.png")
        } catch { }
        
    }
    
    func getElementsFromFile() {
        self.disableAllElements()
        let filePath = "/tmp/get_all_elements_inspector.txt"
        var previousOutput = ""
        self.outputText.string = ""
        self.waitingForFile(fileName: filePath, numberOfRetries: 70) {
            DispatchQueue.main.async {
                if let aStreamReader = StreamReader(path: filePath) {
                    defer {
                        aStreamReader.close()
                    }
                    while let url_line = aStreamReader.nextLine() {
                        
                        self.outputText.string = previousOutput + url_line + "\n"
                        
                        previousOutput = self.outputText.string
                    }
                }
                self.enableAllElements()
                if self.outputText.string.isEmpty {
                    self.outputInTheMainTextView(string: "The simulator seams to be not ready to use. Please use 'Start Simulator' button to start it properly")
                }
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

        let currentChildIndex = uiElements.index(of: item as! String)!
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
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.textColor = NSColor.yellow
                textField.stringValue = item as! String
            }
        } else {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedItemCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.textColor = NSColor.cyan
                textField.stringValue = item as! String
            }
        }
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.cloneButton.isHidden = true
        self.cloneLabel.stringValue = ""
        guard let outlineView = notification.object as? NSOutlineView else { return }
        
        let selectedIndex = outlineView.selectedRow
        
        if let feedItem = outlineView.item(atRow: selectedIndex) as? String {
            let filePath4 = "/tmp/localized.txt"
            
            self.localizedTextField.stringValue = ""
            
            do {
                try fileManager.removeItem(atPath: filePath4)
            } catch { }
            
            self.elementTextField.stringValue = feedItem
        }
    }
}
