import Cocoa
import Foundation
import AppKit
import CommandsCore

class TasksViewController: NSViewController {
    
    //Controller Outlets
    @IBOutlet var outputText: NSTextView!
    @IBOutlet var spinner: NSProgressIndicator!
    @IBOutlet var buildButton: NSButton!
    @IBOutlet var debugCheckbox: NSButton!
    @IBOutlet var phoneComboBox: NSPopUpButton!
    @IBOutlet var languagePopUpButton: NSPopUpButton!
    @IBOutlet var buildPicker: NSPopUpButtonCell!
    @IBOutlet var tagPicker: NSComboBox!
    @IBOutlet var simulator_radio: NSButton!
    @IBOutlet var phys_radio: NSButton!
    @IBOutlet var get_device: NSButtonCell!
    @IBOutlet var cautionImage: NSImageView!
    @IBOutlet var cautionBuildImage: NSImageView!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    let deviceCollector = DeviceCollector()
    var deviceListIsEmpty = false
    var buildItemIsDisabled = false
    @objc dynamic var isRunning = false
    var outputPipeConsole: Pipe?
    var outputPipeTestRun: Pipe?
    var buildTask: Process!
    var buildTask1: Process!
    var buildTask2: Process!
    var buildProcess:Process!
    var killProcessesProcess:Process!
    var sendToIRBSessionProcess:Process!
    var simulatorProcess:Process!
    var generalIRBSessionTask:Process!
    var createIRBSessionTask:Process!
    let env = ProcessInfo.processInfo.environment as [String: String]
    let applicationStateHandler = ApplicationStateHandler()
    let tagsController = TagsController()
    let fileManager = FileManager.default
    var devices: [String] = [""]
    var simulators: [String] = [""]
    var file = ""
    var timer: Timer!
    var pathToCalabashFolder = ""
    
    override func viewDidAppear() {
        super.viewDidAppear()
        let filePath2 = "/tmp/allout.txt"
        let filePath3 = "/tmp/phys_dev.txt"
        let filePath4 = "/tmp/tag_list.txt"
        
        try? fileManager.removeItem(atPath: filePath2)
        try? fileManager.removeItem(atPath: filePath3)
        try? fileManager.removeItem(atPath: filePath4)
        
        
        textField.backgroundColor = .darkAquamarine
        textField.textColor = .white
        let placeholderText = NSMutableAttributedString(string: "Console Input (Beta)")
        placeholderText.setAttributes([.foregroundColor: NSColor.lightGray], range: NSRange(location: 0, length: "Console Input (Beta)".count))
        textField.placeholderAttributedString = placeholderText
        timer = .scheduledTimer(timeInterval: 40, target: self, selector: #selector(self.limitOfChars), userInfo: nil, repeats: true);
        
        // Disable these elements for the moment, as it cannot work for people outside XING
        buildPicker.isEnabled = false
        get_device.isEnabled = false
        phys_radio.isEnabled = false
        simulator_radio.state = .on
        // end
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let filePath = applicationStateHandler.filePath {
            pathToCalabashFolder = filePath.absoluteString.replacingOccurrences(of: "file://", with: "")
        } else if let controller = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "settingswindow")) as? NSViewController {
            presentViewControllerAsModalWindow(controller)
        }
        
        killProcessScreenshot()
        // removes NSUserDefaults for test
//                if let appDomain = Bundle.main.bundleIdentifier {
//                    UserDefaults.standard.removePersistentDomain(forName: appDomain)
//                }
        
        outputText.backgroundColor = .darkAquamarine
        outputText.textColor = .white
        buildPicker.autoenablesItems = false
        cautionBuildImage.isHidden = true
        cautionImage.isHidden = true
        
        if #available(OSX 10.12.2, *) {
            textField.isAutomaticTextCompletionEnabled = true
        }
        
        if phys_radio.state == .on {
            // get_device.isEnabled = true
            languagePopUpButton.isEnabled = false
        } else {
            get_device.isEnabled = false
            languagePopUpButton.isEnabled = true
        }
        
        buildPicker.removeAllItems()
        buildPicker.addItem(withTitle: "1. (master) For simulator(tracking enabled)")
        buildPicker.addItem(withTitle: "2. (master) For physical device")
        buildPicker.addItem(withTitle: "3. (release) For simulator(tracking enabled)")
        buildPicker.addItem(withTitle: "0. Don't download the APP and use the APP from build folder")
        
        tagPicker.completes = true
        killIrbSession()
        runGeneralIrbSession()
        getSimulators()
        
        setupTagSelection()
        
        if let simulatorRadioButtonState = applicationStateHandler.simulatorRadioButtonState,
            let physicalButtonState = applicationStateHandler.physicalButtonState {
            simulator_radio.state = NSControl.StateValue(rawValue: simulatorRadioButtonState)
            phys_radio.state = physicalButtonState
        }
        
        disableBuildItems()
        
        let filePath2 = "/tmp/allout.txt"
        let filePath3 = "/tmp/phys_dev.txt"
        
        if let bStreamReader = StreamReader(path: filePath2) {
            defer {
                bStreamReader.close()
            }
            while var line = bStreamReader.nextLine() {
                line = line.trimmingCharacters(in: .whitespaces)
                phoneComboBox.addItem(withTitle: line)
            }
        }
        
        
        simulators = phoneComboBox.itemTitles
        
        phoneComboBox.removeAllItems()
        
        if let bStreamReader = StreamReader(path: filePath3) {
            defer {
                bStreamReader.close()
            }
            while var line = bStreamReader.nextLine() {
                line = line.trimmingCharacters(in: .whitespaces)
                phoneComboBox.addItem(withTitle: line)
            }
        }
        
        devices = phoneComboBox.itemTitles
        
        phoneComboBox.removeAllItems()
        
        if simulator_radio.state == .on {
            languagePopUpButton.isEnabled = true
            phoneComboBox.addItems(withTitles: simulators)
        } else {
            get_device.isEnabled = true
            languagePopUpButton.isEnabled = false
            phoneComboBox.addItems(withTitles: devices)
        }
        
        phoneComboBox.selectItem(at: 0)
        
        if !phoneComboBox.itemTitles.isEmpty {
            for index in 0...phoneComboBox.itemTitles.count - 1 {
                if phoneComboBox.itemTitles[index].contains("iPhone 7 (") {
                    phoneComboBox.selectItem(at: index)
                    break
                }
            }
        }
        
        if phoneComboBox.selectedItem == nil {
            deviceListIsEmpty = true
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let noConnectedDevices = "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.installSimulatorOrPluginDevice)"
            phoneComboBox.addItem(withTitle: noConnectedDevices)
            let previousOutput2 = outputText.string
            outputText.string = "\(previousOutput2)\n\(noConnectedDevices)"
        } else {
            cautionImage.isHidden = true
            deviceListIsEmpty = false
        }
        
        // State recovery
        buildPicker.selectItem(at: applicationStateHandler.buildNumber)
        
        disableBuildItems()
        
        if let phoneName = applicationStateHandler.phoneName {
            phoneComboBox.selectItem(withTitle: phoneName)
        }
        
        if let language = applicationStateHandler.language {
            languagePopUpButton.selectItem(withTitle: language)
            
            if phoneComboBox.selectedItem == nil {
                phoneComboBox.selectItem(at: 0)
            }
        }
        
        if let tag = applicationStateHandler.tag {
            tagPicker.selectItem(withObjectValue: tag)
        }
        
        if let debugState = applicationStateHandler.debugState {
            debugCheckbox.state = NSControl.StateValue(rawValue: debugState)
        }
        
        applicationStateHandler.phoneName = phoneComboBox.titleOfSelectedItem
        applicationStateHandler.phoneUDID = getCurrentDeviceUDID()
    }
    
    private func setupTagSelection() {
        tagsController.tags(in: pathToCalabashFolder).forEach({ (tag) in
            self.tagPicker.addItem(withObjectValue: tag)
        })
    }

    func killProcessScreenshot() {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        
        taskQueueNew.sync {
            let path = Constants.FilePaths.Bash.killProcess
            killProcessesProcess = Process()
            killProcessesProcess.launchPath = path
            killProcessesProcess.terminationHandler = { task in
                DispatchQueue.main.sync {
                }
            }
            killProcessesProcess.launch()
            killProcessesProcess.waitUntilExit()
        }
    }
    
    @IBAction func buildPicker(_ sender: Any) {
        if buildPicker.selectedItem?.isEnabled == true {
            cautionBuildImage.isHidden = true
            buildItemIsDisabled = false
        }
        statePreservation()
    }
    
    @IBAction func clearBufferButton(_ sender: Any) {
        outputText.string = ""
    }
    
    @IBAction func settingsButton(_ sender: Any) {
        if let controller = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "settingswindow")) as? NSViewController {
            presentViewControllerAsSheet(controller)
        }
    }
    
    @IBAction func get_device(_ sender: Any) {
        spinner.startAnimation(self)
        progressBar.startAnimation(self)
        
        simulator_radio.state = .off
        
        getSimulators()
        
        phoneComboBox.removeAllItems()
        
        let filePath6 = "/tmp/phys_dev.txt"
        let filePath7 = "/tmp/allout.txt"
        
        if let bStreamReader = StreamReader(path: filePath6) {
            defer {
                bStreamReader.close()
            }
            while var line = bStreamReader.nextLine() {
                line = line.trimmingCharacters(in: .whitespaces)
                phoneComboBox.addItem(withTitle: line)
            }
        }
        
        try? fileManager.removeItem(atPath: filePath6)
        try? fileManager.removeItem(atPath: filePath7)
        
        if phoneComboBox.selectedItem == nil {
            deviceListIsEmpty = true
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            phoneComboBox.addItem(withTitle: "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.pluginDevice)")
        } else {
            cautionImage.isHidden = true
            deviceListIsEmpty = false
        }
        
        spinner.stopAnimation(self)
        progressBar.stopAnimation(self)
        
        devices = self.phoneComboBox.itemTitles
    }
    
    @IBAction func simulator_radio(_ sender: Any) {
        phys_radio.state = .off
        get_device.isEnabled = false
        languagePopUpButton.isEnabled = true
        
        phoneComboBox.removeAllItems()
        
        phoneComboBox.addItems(withTitles: simulators)
        
        if let phoneName = applicationStateHandler.phoneName,
            phoneName != "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.pluginDevice)" {
            phoneComboBox.selectItem(withTitle: phoneName)
        } else if !phoneComboBox.itemTitles.isEmpty {
            for index in 0...phoneComboBox.itemTitles.count - 1 {
                if phoneComboBox.itemTitles[index].contains("iPhone 7 (") {
                    phoneComboBox.selectItem(at: index)
                    break
                }
            }
        }
        
        if phoneComboBox.selectedItem == nil {
            deviceListIsEmpty = true
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let noConnectedSimulators = "\(Constants.Strings.noSimulatorsConnected) \(Constants.Strings.installSimulator)"
            phoneComboBox.addItem(withTitle: noConnectedSimulators)
            let previousOutput3 = outputText.string
            outputText.string = "\(previousOutput3)\n\(noConnectedSimulators)"
        } else {
            cautionImage.isHidden = true
            deviceListIsEmpty = false
        }
        disableBuildItems()
    }
    
    @IBAction func phys_radio(_ sender: Any) {
        get_device.isEnabled = true
        languagePopUpButton.isEnabled = false
        simulator_radio.state = .off
        
        phoneComboBox.removeAllItems()
        
        phoneComboBox.addItems(withTitles: devices)
        
        if phoneComboBox.selectedItem == nil {
            deviceListIsEmpty = true
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            phoneComboBox.addItem(withTitle: "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.pluginDevice)")
        } else {
            cautionImage.isHidden = true
            deviceListIsEmpty = false
        }
        disableBuildItems()
    }
    
    
    @IBAction func startTask(_ sender:AnyObject) {
        statePreservation()
        
        if deviceListIsEmpty == true {
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let previousOutput4 = outputText.string
            outputText.string = "\(previousOutput4)\n\(Constants.Strings.noDevicesConnected) \(Constants.Strings.installSimulatorOrPluginDevice)"
            return
        } else {
            cautionImage.isHidden = true
        }
        
        if buildItemIsDisabled {
            let previousOutput6 = outputText.string
            outputText.string = "\(previousOutput6)\n'\(buildPicker.titleOfSelectedItem ?? "unknown item"))' \(Constants.Strings.notCompatibleWithDeviceType)"
            return
        }
        
        
        file = "file://\(pathToCalabashFolder)/build_to_download.txt"
        let fileURL = URL(string: file)
        var text = String(buildPicker.indexOfSelectedItem + 1)
        
        if buildPicker.indexOfSelectedItem + 1 == buildPicker.numberOfItems {
            text = "0"
        }
        
        do {
            if let fileURL = fileURL {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
        } catch { }
        
        var arguments: [String] = []
        
        if debugCheckbox.state == .on {
            arguments.append("DEBUG=1")
        } else {
            arguments.append("DEBUG=0")
        }
        
        if phys_radio.state == .on {
            //arguments.append("DEVICE_IP=http://\(device_name.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "\'", with: "")).xing.hh:37265")
            arguments.append("phys_device")
            if applicationStateHandler.isLaunched == false {
                // Will keep it for now. Have to re-write the installation methods https://source.xing.com/serghei-moret/calabash_launcher/issues/28
                applicationStateHandler.isLaunched = true
            }
        } else {
            let simulatorUDID = getCurrentDeviceUDID()
            arguments.append("DEVICE_TARGET=\(simulatorUDID)")
        }
        
        arguments.append(pathToCalabashFolder)

        if let cucumberProfile = applicationStateHandler.cucumberProfile, !cucumberProfile.isEmpty {
            arguments.append("-p \(cucumberProfile)")
        }
        
        if !tagPicker.stringValue.isEmpty {
            arguments.append("--t @\(tagPicker.stringValue)")
        }
        
        buildButton.isEnabled = false
        spinner.startAnimation(self)
        progressBar.startAnimation(self)
        runScript(arguments)
    }
    
    @IBAction func textField(_ sender: Any) {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        taskQueueNew.sync {
            let path = Constants.FilePaths.Bash.sendToIRB
            sendToIRBSessionProcess = Process()
            sendToIRBSessionProcess.launchPath = path
            
            var arguments: [String] = []
            arguments.append(textField.stringValue)
            
            sendToIRBSessionProcess.arguments = arguments
            
            sendToIRBSessionProcess.terminationHandler = { task in
                DispatchQueue.main.sync {
                    
                }
            }
            
            sendToIRBSessionProcess.launch()
            sendToIRBSessionProcess.waitUntilExit()
        }
        
        outputInTheMainTextView(string: textField.stringValue)
        textField.stringValue = ""
    }
    
    @IBAction func toggleDebug(_ sender: NSButton) {
        applicationStateHandler.debugState = sender.state.rawValue
    }
    
    func outputInTheMainTextView(string: String) {
        let attrString = NSMutableAttributedString(string: string)
        attrString.setAttributes([.foregroundColor: NSColor.white], range: NSRange(location: 0, length: string.count))
        outputText.textStorage?.append(NSMutableAttributedString(string: "\n"))
        outputText.textStorage?.append(attrString)
        outputText.textStorage?.append(NSMutableAttributedString(string: "\n"))
        
        let range = NSRange(location: outputText.string.count, length: 0)
        outputText.scrollRangeToVisible(range)
    }
    
    @IBAction func stopTask(_ sender:AnyObject) {
        
        do {
            try fileManager.removeItem(atPath: file
                .replacingOccurrences(of: "file://", with: "")
                .replacingOccurrences(of: "//", with: "/"))
        } catch { }
        
        if isRunning {
            buildProcess.terminate()
        }
    }

    @IBAction func clickPhoneChooser(_ sender: Any) {
        applicationStateHandler.phoneName = phoneComboBox.titleOfSelectedItem
        applicationStateHandler.phoneUDID = getCurrentDeviceUDID()
    }
    
    @IBAction func languageOptionsButton(_ sender: Any) {
        applicationStateHandler.language = languagePopUpButton.title
        if let controller = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "languagesettings")) as? NSViewController {
            presentViewControllerAsModalWindow(controller)
        }
    }
    
    @IBAction func languageSwitchButton(_ sender: Any) {
        changeLocale()
    }
    
    @IBAction func languagePopUp(_ sender: Any) {
        applicationStateHandler.language = languagePopUpButton.title
    }
    
    func captureStandardOutputAndRouteToTextView(_ task: Process, outputPipe: Pipe) {
        task.standardOutput = outputPipe
        task.standardError = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: .utf8) ?? ""
            
            if outputString != "nil\n" {
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    if !outputString.isEmpty {
                        ColorizeBashOutput().colorizeTheOutput(outputRawString: outputString, obj: strongSelf)
                    }
                    
                    let range = NSRange(location: strongSelf.outputText.string.count, length: 0)
                    strongSelf.outputText.scrollRangeToVisible(range)
                    
                }
            }
            
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    
    
    @objc func limitOfChars() {
        let maxCharacters = 40000
        let characterCount = outputText.string.count
        
        if characterCount > maxCharacters {
            outputText.textStorage?.deleteCharacters(in: NSRange(location: 1, length: characterCount - maxCharacters))
        }
    }
    
    func disableBuildItems() {
        if simulator_radio.state == .on {
            buildPicker.item(at: 0)?.isEnabled = true
            buildPicker.item(at: 1)?.isEnabled = false
            buildPicker.item(at: 2)?.isEnabled = true
        } else {
            buildPicker.item(at: 0)?.isEnabled = false
            buildPicker.item(at: 1)?.isEnabled = true
            buildPicker.item(at: 2)?.isEnabled = false
        }
        
        if buildPicker.selectedItem?.isEnabled == false {
            cautionBuildImage.isHidden = false
            buildItemIsDisabled = true
        } else {
            cautionBuildImage.isHidden = true
            buildItemIsDisabled = false
        }
    }
    
    func getSimulators() {
        spinner.startAnimation(self)
        progressBar.startAnimation(self)
        get_device.isEnabled = false
        isRunning = true
        
        deviceCollector.simulators(completion: {
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.buildButton.isEnabled = true
                strongSelf.get_device.isEnabled = true
                strongSelf.spinner.stopAnimation(strongSelf)
                strongSelf.progressBar.stopAnimation(strongSelf)
                strongSelf.isRunning = false
            }
        }) { output in
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let strongSelf = self else { return }
                let previousOutput = strongSelf.outputText.string
                if !output.isEmpty {
                    let nextOutput = "\(previousOutput)\n\(output)"
                    strongSelf.outputText.string = nextOutput
                    
                    let range = NSRange(location: nextOutput.count, length: 0)
                    strongSelf.outputText.scrollRangeToVisible(range)
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.buildButton.isEnabled = true
            strongSelf.get_device.isEnabled = true
            strongSelf.spinner.stopAnimation(strongSelf)
            strongSelf.progressBar.stopAnimation(strongSelf)
            strongSelf.isRunning = false
        }
    }

    func killIrbSession() {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        taskQueueNew.sync { [weak self] in
            guard let strongSelf = self else { return }
            let path = Constants.FilePaths.Bash.quitIRBSession
            strongSelf.generalIRBSessionTask = Process()
            strongSelf.generalIRBSessionTask.launchPath = path
            
            strongSelf.generalIRBSessionTask.terminationHandler = { task in
                DispatchQueue.main.sync {
                    
                }
            }
            
            strongSelf.generalIRBSessionTask.launch()
            strongSelf.generalIRBSessionTask.waitUntilExit()
        }
    }
    
    func statePreservation() {
        applicationStateHandler.simulatorRadioButtonState = simulator_radio.state.rawValue
        applicationStateHandler.physicalButtonState = phys_radio.state
        applicationStateHandler.buildNumber = buildPicker.indexOfSelectedItem
        applicationStateHandler.phoneName = phoneComboBox.titleOfSelectedItem
        applicationStateHandler.language = languagePopUpButton.title
        applicationStateHandler.tag = tagPicker.stringValue
        applicationStateHandler.debugState = debugCheckbox.state.rawValue
    }
    
    func runScript(_ arguments: [String]) {
        isRunning = true
        
        let taskQueue33 = DispatchQueue.global(qos: .background)
        
        spinner.startAnimation(self)
        progressBar.startAnimation(self)
        
        taskQueue33.async { [weak self] in
            guard let strongSelf = self else { return }
            let path = Constants.FilePaths.Bash.buildScript
            
            strongSelf.buildProcess = Process()
            strongSelf.buildProcess.launchPath = path
            strongSelf.buildProcess.arguments = arguments
            
            strongSelf.buildProcess.terminationHandler = { task in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.buildButton.isEnabled = true
                    strongSelf.spinner.stopAnimation(strongSelf)
                    strongSelf.progressBar.stopAnimation(strongSelf)
                    strongSelf.isRunning = false
                }
            }
            
            strongSelf.outputPipeTestRun = Pipe()
            if let testRunOutputPipe = strongSelf.outputPipeTestRun {
                strongSelf.captureStandardOutputAndRouteToTextView(strongSelf.buildProcess, outputPipe: testRunOutputPipe)
            }
            strongSelf.buildProcess.launch()
            strongSelf.buildProcess.waitUntilExit()
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.buildButton.isEnabled = true
                strongSelf.spinner.stopAnimation(strongSelf)
                strongSelf.progressBar.stopAnimation(strongSelf)
                strongSelf.isRunning = false
            }
        }
    }
    
    func runGeneralIrbSession() {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        
        taskQueueNew.async { [weak self] in
            guard let strongSelf = self else { return }
            let path = Constants.FilePaths.Bash.createIRBSession
            strongSelf.createIRBSessionTask = Process()
            strongSelf.createIRBSessionTask.launchPath = path
            var arguments: [String] = []
            strongSelf.createIRBSessionTask.arguments = arguments
            arguments.append(strongSelf.pathToCalabashFolder)
            if let helpersPath = Constants.FilePaths.Ruby.helpers {
                arguments.append(helpersPath)
            }
            strongSelf.createIRBSessionTask.arguments = arguments
            strongSelf.outputPipeConsole = Pipe()
            if let consoleOutputPipe = strongSelf.outputPipeConsole {
                strongSelf.captureStandardOutputAndRouteToTextView(strongSelf.createIRBSessionTask, outputPipe: consoleOutputPipe)
            }
            strongSelf.createIRBSessionTask.launch()
            strongSelf.createIRBSessionTask.waitUntilExit()
        }
    }
    
    func getCurrentDeviceUDID() -> String {
        let simulatorUDIDs = phoneComboBox.itemTitle(at: phoneComboBox.indexOfSelectedItem)
            .split(separators: "[]")
            .map(String.init)
        if simulatorUDIDs.count >= 2 {
            return simulatorUDIDs[1]
        }
        return ""
    }
    
    func changeLocale() {
        var locale = "en"
        var willRun = true
        let titleLanguage = Language(rawValue: languagePopUpButton.title )
        switch titleLanguage {
        case .english?:
            locale = Language.english.identifier
        case .german?:
             locale = Language.german.identifier
        case .russian?:
            locale = Language.russian.identifier
        case .italian?:
            locale = Language.italian.identifier
        case .french?:
            locale = Language.french.identifier
        case .polish?:
            locale = Language.polish.identifier
        case .other?:
            willRun = false
        default:
            print("Unknown language")
        }
        
        if willRun {
            let simUDID = getCurrentDeviceUDID()
            let arguments = ["Commands", Constants.FilePaths.Bash.changeLanguage, simUDID, locale]
            let commands = Commands(arguments: arguments as! [String])
            try? commands.run()
        }
    }
}

