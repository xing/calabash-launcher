import AppKit
import CommandsCore

class TasksViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView!
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
    
    let localization = Localization()
    let deviceCollector = DeviceCollector()
    var textViewPrinter: TextViewPrinter!
    var deviceListIsEmpty = false
    var buildItemIsDisabled = false
    @objc dynamic var isRunning = false
    var buildProcess:Process!
    var killProcessesProcess:Process!
    var sendToIRBSessionProcess:Process!
    var generalIRBSessionTask:Process!
    let env = ProcessInfo.processInfo.environment as [String: String]
    let applicationStateHandler = ApplicationStateHandler()
    let tagsController = TagsController()
    let fileManager = FileManager.default
    var devices: [String] = [""]
    var file = ""
    var timer: Timer!
    var pathToCalabashFolder = ""
    
    override func viewDidAppear() {
        super.viewDidAppear()
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

        textViewPrinter = TextViewPrinter(textView: textView)
        
        let languageValues = Language.all.map { $0.rawValue }
        languagePopUpButton.addItems(withTitles: languageValues)
        
        if let filePath = applicationStateHandler.filePath {
            pathToCalabashFolder = filePath.absoluteString.replacingOccurrences(of: "file://", with: "")
        } else if let controller = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "settingswindow")) as? NSViewController {
            presentViewControllerAsModalWindow(controller)
        }
        
        killProcessScreenshot()
        // removes NSUserDefaults for test
//        if let appDomain = Bundle.main.bundleIdentifier {
//            UserDefaults.standard.removePersistentDomain(forName: appDomain)
//        }

        textView.backgroundColor = .darkAquamarine
        textView.textColor = .white
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
        
        tagPicker.completes = true
        killIrbSession()
        runGeneralIrbSession()
        setupTagSelection()
        
        if let simulatorRadioButtonState = applicationStateHandler.simulatorRadioButtonState,
            let physicalButtonState = applicationStateHandler.physicalButtonState {
            simulator_radio.state = NSControl.StateValue(rawValue: simulatorRadioButtonState)
            phys_radio.state = physicalButtonState
        }
        
        disableBuildItems()
        
        getSimulators()
        selectDeviceIfAvailable(prefixed: "iPhone 7(")

        if phoneComboBox.selectedItem == nil {
            deviceListIsEmpty = true
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let noConnectedDevices = "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.installSimulatorOrPluginDevice)"
            phoneComboBox.addItem(withTitle: noConnectedDevices)
            let previousOutput2 = textView.string
            textView.string = "\(previousOutput2)\n\(noConnectedDevices)"
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
        applicationStateHandler.phoneUDID = deviceCollector.getDeviceUDID(device: phoneComboBox.itemTitle(at: phoneComboBox.indexOfSelectedItem))
    }
    
    private func setupTagSelection() {
        tagsController.tags(in: pathToCalabashFolder).forEach { tag in
            self.tagPicker.addItem(withObjectValue: tag)
        }
    }

    func killProcessScreenshot() {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        
        taskQueueNew.sync {
            let path = Constants.FilePaths.Bash.killProcess
            killProcessesProcess = Process()
            killProcessesProcess.launchPath = path
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
        textView.string = ""
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
    }
    
    @IBAction func simulator_radio(_ sender: Any) {
        phys_radio.state = .off
        get_device.isEnabled = false
        languagePopUpButton.isEnabled = true

        if let phoneName = applicationStateHandler.phoneName,
            phoneName != "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.pluginDevice)" {
            phoneComboBox.selectItem(withTitle: phoneName)
        } else {
            selectDeviceIfAvailable(prefixed: "iPhone 7(")
        }
        
        if phoneComboBox.selectedItem == nil {
            deviceListIsEmpty = true
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let noConnectedSimulators = "\(Constants.Strings.noSimulatorsConnected) \(Constants.Strings.installSimulator)"
            phoneComboBox.addItem(withTitle: noConnectedSimulators)
            let previousOutput3 = textView.string
            textView.string = "\(previousOutput3)\n\(noConnectedSimulators)"
        } else {
            cautionImage.isHidden = true
            deviceListIsEmpty = false
        }
        disableBuildItems()
    }

    private func selectDeviceIfAvailable(prefixed device: String) {
        if !phoneComboBox.itemTitles.isEmpty, let deviceTitle = phoneComboBox.itemTitles.first(where: { $0.contains(device) }) {
            phoneComboBox.selectItem(withTitle: deviceTitle)
        }
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
            let previousOutput4 = textView.string
            textView.string = "\(previousOutput4)\n\(Constants.Strings.noDevicesConnected) \(Constants.Strings.installSimulatorOrPluginDevice)"
            return
        } else {
            cautionImage.isHidden = true
        }
        
        if buildItemIsDisabled {
            let previousOutput6 = textView.string
            textView.string = "\(previousOutput6)\n'\(buildPicker.titleOfSelectedItem ?? "unknown item"))' \(Constants.Strings.notCompatibleWithDeviceType)"
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
            arguments.append("phys_device")
            if applicationStateHandler.isLaunched == false {
                // Will keep it for now. Have to re-write the installation methods https://source.xing.com/serghei-moret/calabash_launcher/issues/28
                applicationStateHandler.isLaunched = true
            }
        } else {
            arguments.append("DEVICE_TARGET=\(applicationStateHandler.phoneUDID ?? "")")
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
            
            sendToIRBSessionProcess.arguments = [textField.stringValue]
            
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
        textView.textStorage?.append(NSMutableAttributedString(string: "\n"))
        textView.textStorage?.append(attrString)
        textView.textStorage?.append(NSMutableAttributedString(string: "\n"))
        
        let range = NSRange(location: textView.string.count, length: 0)
        textView.scrollRangeToVisible(range)
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
        applicationStateHandler.phoneUDID = deviceCollector.getDeviceUDID(device: phoneComboBox.itemTitle(at: phoneComboBox.indexOfSelectedItem))
    }
    
    @IBAction func languageSwitchButton(_ sender: Any) {
        localization.changeDefaultLocale(language: languagePopUpButton.title)
    }
    
    @IBAction func languagePopUp(_ sender: Any) {
        applicationStateHandler.language = languagePopUpButton.title
        if let controller = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "languagesettings")) as? NSViewController, languagePopUpButton.title == Language.other.rawValue {
            presentViewControllerAsModalWindow(controller)
        }
    }

    @objc func limitOfChars() {
        let maxCharacters = 40000
        let characterCount = textView.string.count
        
        if characterCount > maxCharacters {
            textView.textStorage?.deleteCharacters(in: NSRange(location: 1, length: characterCount - maxCharacters))
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
        
        if let launchPath = Constants.FilePaths.Bash.simulators {
            let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = { text in
                DispatchQueue.main.async {
                    let filderedText = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                    self.phoneComboBox.addItems(withTitles: filderedText)
                }
            }
            let commands = CommandsCore.CommandExecutor()
            commands.executeCommand(at: launchPath, arguments: [""], outputStream: outputStream)
        }
        
        buildButton.isEnabled = true
        spinner.stopAnimation(self)
        get_device.isEnabled = true
        progressBar.stopAnimation(self)
        isRunning = false
    }

    func killIrbSession() {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        taskQueueNew.sync { [weak self] in
            guard let strongSelf = self else { return }
            let path = Constants.FilePaths.Bash.quitIRBSession
            strongSelf.generalIRBSessionTask = Process()
            strongSelf.generalIRBSessionTask.launchPath = path
            
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
        spinner.startAnimation(self)
        progressBar.startAnimation(self)
        
        if let launchPath = Constants.FilePaths.Bash.buildScript {
            let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = { text in
                DispatchQueue.main.async {
                    self.textViewPrinter.printToTextView(text)
                }
            }
            let commands = CommandsCore.CommandExecutor()
            commands.executeCommand(at: launchPath, arguments: arguments, outputStream: outputStream)
        }
        
        buildButton.isEnabled = true
        spinner.stopAnimation(self)
        progressBar.stopAnimation(self)
        isRunning = false
    }
    
    func runGeneralIrbSession() {
        if let launchPath = Constants.FilePaths.Bash.createIRBSession {
            let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = {text in
                DispatchQueue.main.async {
                    self.textViewPrinter.printToTextView(text)
                }
            }
            var arguments: [String] = []
            arguments.append(pathToCalabashFolder)
            if let helpersPath = Constants.FilePaths.Ruby.helpers {
                arguments.append(helpersPath)
            }
            let commands = CommandsCore.CommandExecutor()
            DispatchQueue.global(qos: .background).async {
                commands.executeCommand(at: launchPath, arguments: arguments, outputStream: outputStream)
            }
        }
    }
}
