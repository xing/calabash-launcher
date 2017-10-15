import Cocoa
import Foundation
import AppKit

class InspectorViewController: NSViewController, NSTableViewDataSource {

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
    var elements_list:[String] = []
    var parent_collection_list:[String] = []
    var parent_collection_cut_list:[String] = []
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
    @IBOutlet var getScreen: NSButtonCell!
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
        self.getScreen.isEnabled = false
        }
        }

    func enableAllElements() {
        isRunning = false
        DispatchQueue.main.async {
        self.startDeviceButton.isEnabled = true
        self.getElementsButton.isEnabled = true
        self.spinner.stopAnimation(self)
        self.gestureRecognizer.isEnabled = true
        self.getScreen.isEnabled = true
    }
    }
    
    override func viewDidAppear() {
        self.outputText.backgroundColor = NSColor.init(red:0.18, green:0.33, blue:0.43, alpha:1.0)
        self.outputText.textColor = NSColor.init(red:0.00, green:1.00, blue:0.28, alpha:1.0)
        localizedTextField.textColor = NSColor.black
        elementTextField.textColor = NSColor.black
        self.outlineView.backgroundColor = NSColor.init(red:0.18, green:0.33, blue:0.43, alpha:1.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       //calabashIsRunning()
        
        self.getHomeDirectoryPath()
        gestureRecognizableView.addGestureRecognizer(gestureRecognizer)
        coordinatesMarker.isHidden = true
        
        
            self.getScreen.isEnabled = true
            self.getElementsButton.isEnabled = true
            self.startDeviceButton.isEnabled = true
            self.gestureRecognizer.isEnabled = true
            self.cloneButton.isHidden = true
    }

    func setUserDefaultsListener(){
        UserDefaults.standard.addObserver(self, forKeyPath: "FilePath", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
   override func observeValue(forKeyPath: String?, of: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
       if forKeyPath == "FilePath" {
            self.getHomeDirectoryPath()
        
                self.getScreen.isEnabled = true
                self.getElementsButton.isEnabled = true
                self.startDeviceButton.isEnabled = true
                self.gestureRecognizer.isEnabled = true
        
        }
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "FilePath")
    }
    
    
    @IBAction func doubleClickedItem(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        if item != nil {
            flashElement(element: item as! String)
        }
    }

    
    @IBAction func getScreen(_ sender: Any) {
        timer.invalidate()
        coordinatesMarker.isHidden = true
        syncScreen()
        getScreenProcs()
        timer = Timer.scheduledTimer(timeInterval: 5.5, target: self, selector: #selector(self.getScreenProcsLoop), userInfo: nil, repeats: true);
    }
    
    @IBAction func gestureRecognizer(_ sender: Any) {
       let coordinates = gestureRecognizer.location(in: gestureRecognizableView)
        self.coordinatesMarker.isHidden = false
        self.coordinatesMarker.isHighlighted = true
        let convertedClickPoint = self.gestureRecognizableView.convert(coordinates, to: self.view)
        self.coordinatesMarker.frame = NSRect(x: convertedClickPoint.x - self.coordinatesMarker.frame.size.width/2 + 1, y: convertedClickPoint.y - self.coordinatesMarker.frame.size.height/2 - 6, width: self.coordinatesMarker.frame.size.width, height: self.coordinatesMarker.frame.size.height)
        var arguments:[String] = []
        elements_list = []
        parent_collection_list = []
        var parent_trigger = 0
        
        arguments.append(coordinates.x.description)
        arguments.append(coordinates.y.description)
        Shared.shared.coordinates = []
        Shared.shared.coordinates.append(coordinates.x.description)
        Shared.shared.coordinates.append(coordinates.y.description)
        do {
            try fileManager.removeItem(atPath: "/tmp/element_array.txt")
        } catch _ as NSError {}
        
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
                    self.elements_list.append(url_line)
                } else if parent_trigger == 2 {
                    self.parent_collection_list.append(url_line)
                }
            }
            
            if self.elements_list == [] {
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
                            self.elements_list.append(url_line)
                        } else if parent_trigger == 2 {
                            self.parent_collection_list.append(url_line)
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
            
            self.buildTaskNew558.terminationHandler = {
                task in
                
                DispatchQueue.main.sync(execute: {
                    
                })
                
            }
            
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
    
    func fileIsNotEmpty(filePath: String)->Bool {
        
        if filePath.range(of: "txt") == nil {
            return true
        } else {
        var found:Bool = false
        if let aStreamReader = StreamReader(path: filePath) {
            defer {
                aStreamReader.close()
            }
            if aStreamReader.nextLine() != nil {
                found = true
            }
        }
        if found {
            return true
        } else {
            return false
        }
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
            self.pathToCalabashFolder = (env["HOME"]! + "/" + path_string.replacingOccurrences(of: env["HOME"]!, with: "")).replacingOccurrences(of: "~/", with: "").replacingOccurrences(of: "file://", with: "")
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
        } catch _ as NSError {}
        
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
    

    func syncScreen() {
        
        do {
            try fileManager.removeItem(atPath: "/tmp/screenshot_0.png")
        } catch _ as NSError {
        }
        
        let taskQueue9 = DispatchQueue.global(qos: .background)
        
        taskQueue9.async {
            let path = Constants.FilePaths.Bash.screen
            self.runDeviceTask3 = Process()
           
            self.runDeviceTask3.launchPath = path
            var arguments:[String] = []
            arguments.append(self.pathToCalabashFolder)
            
            self.runDeviceTask3.arguments = arguments
            
            self.runDeviceTask3.launch()

        }
        
    }
    

    func captureStandardOutputAndRouteToTextView(_ task:Process) {

        outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { notification in
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            DispatchQueue.main.async(execute: {
                let previousOutput = self.outputText.string
                
                
                if outputString.count > 0 {
                    
                    let nextOutput = previousOutput + "\n" + outputString
                    self.outputText.string = nextOutput
                    
                    let range = NSRange(location: nextOutput.count, length: 0)
                    self.outputText.scrollRangeToVisible(range)
                }
            })
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
    
    func changeScreenshot() {
        let imageURL = URL(fileURLWithPath: "/tmp/screenshot_0.png")
        let image = NSImage(contentsOfFile: imageURL.path)
        DispatchQueue.main.async {
            self.gestureRecognizableView.image = image
        }
        
        do {
            try fileManager.removeItem(atPath: "/tmp/screenshot_0.png")
        } catch _ as NSError {
        }
        
    }
    
    func getScreenProcs() {
        
        self.waitingForFile(fileName: "/tmp/screenshot_0.png", numberOfRetries: 40) {
            

        let imageURL = URL(fileURLWithPath: "/tmp/screenshot_0.png")
        let image = NSImage(contentsOfFile: imageURL.path)
        DispatchQueue.main.async {
                self.gestureRecognizableView.image = image
            }
        do {
            try self.fileManager.removeItem(atPath: "/tmp/screenshot_0.png")
        } catch _ as NSError {
        }
                self.enableAllElements()
        }
        
    }
    
    func flashElement(element : String) {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        
        taskQueueNew.async {
            let path = Constants.FilePaths.Bash.flash
            self.buildTaskNew12 = Process()
            self.buildTaskNew12.launchPath = path
            var arguments:[String] = []
            arguments.append(element)
            self.buildTaskNew12.arguments = arguments
            self.buildTaskNew12.launch()
        }
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
        parent_collection_cut_list = []
        if item == nil {
            isParentView = false
            return elements_list.count
        } else {
            let current_child_index = elements_list.index(of: item! as! String)!
            isParentView = true
            
            var calculated_child_index:Int = -1
            
            if parent_collection_list.count == 0 {
                    return 0
            }
            
            for i in 0...parent_collection_list.count - 1 {
                
                if parent_collection_list[i] == "\"separator\"" {
                    calculated_child_index = calculated_child_index + 1
                    continue
                }
            
                if calculated_child_index == current_child_index {
                    parent_collection_cut_list.append(parent_collection_list[i])
                }
            }
            
            return parent_collection_cut_list.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if !isParentView {
            elementIndex = index
            return elements_list[index]
        } else {
            parentElementIndex = index
            return parent_collection_cut_list[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if !isParentView {
            return true
        } else {
            return false
        }
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
        guard let outlineView = notification.object as? NSOutlineView else {
            return
        }
        
        //2
        let selectedIndex = outlineView.selectedRow
        
        if let feedItem = outlineView.item(atRow: selectedIndex) as? String {
            
            let filePath4 = "/tmp/localized.txt"
            
            self.localizedTextField.stringValue = ""
            
            do {
                try fileManager.removeItem(atPath: filePath4)
            } catch _ as NSError {}
            
            self.elementTextField.stringValue = feedItem
            if elements_list.count != 0 {
        }
        
        }
    }
}

final class Shared {
    static let shared = Shared()
    
    var stringValue: String!
    var coordinates: [String]!
}
