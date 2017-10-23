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
    @IBOutlet var simulatorRadioButton: NSButton!
    @IBOutlet var physicalDeviceRadioButton: NSButton!
    @IBOutlet var getDeviceButton: NSButtonCell!
    @IBOutlet var cautionImage: NSImageView!
    @IBOutlet var cautionBuildImage: NSImageView!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    let localization = Localization()
    let deviceCollector = DeviceCollector()
    var textViewPrinter: TextViewPrinter!
    let commands = CommandsCore.CommandExecutor()
    var deviceListIsEmpty = false
    @objc dynamic var isRunning = false
    let applicationStateHandler = ApplicationStateHandler()
    let tagsController = TagsController()
    var devices = [""]
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
        getDeviceButton.isEnabled = false
        physicalDeviceRadioButton.isEnabled = false
        simulatorRadioButton.state = .on
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

        textView.backgroundColor = .darkAquamarine
        textView.textColor = .white
        buildPicker.autoenablesItems = false
        cautionBuildImage.isHidden = true
        cautionImage.isHidden = true
        
        if #available(OSX 10.12.2, *) {
            textField.isAutomaticTextCompletionEnabled = true
        }
        
        if physicalDeviceRadioButton.state == .on {
            // get_device.isEnabled = true
            languagePopUpButton.isEnabled = false
        } else {
            getDeviceButton.isEnabled = false
            languagePopUpButton.isEnabled = true
        }
        
        tagPicker.completes = true
        runGeneralIrbSession()
        DispatchQueue.global(qos: .background).async {
            self.setupTagSelection()
            if let tag = self.applicationStateHandler.tag {
                DispatchQueue.main.async {
                    self.tagPicker.selectItem(withObjectValue: tag)
                }
            }
        }
        
        if let simulatorRadioButtonState = applicationStateHandler.simulatorRadioButtonState,
            let physicalButtonState = applicationStateHandler.physicalButtonState {
            simulatorRadioButton.state = NSControl.StateValue(rawValue: simulatorRadioButtonState)
            physicalDeviceRadioButton.state = physicalButtonState
        }

        DispatchQueue.global(qos: .background).async {
            self.getSimulators()
        }
        
        // State recovery
        if let language = applicationStateHandler.language {
            languagePopUpButton.selectItem(withTitle: language)
        }
        
        if let debugState = applicationStateHandler.debugState {
            debugCheckbox.state = NSControl.StateValue(rawValue: debugState)
        }
    }
    
    private func setupTagSelection() {
        tagsController.tags(in: pathToCalabashFolder).forEach { tag in
            DispatchQueue.main.async {
                self.tagPicker.addItem(withObjectValue: tag)
            }
        }
    }

    func killProcessScreenshot() {
        commands.executeCommand(at: Constants.FilePaths.Bash.killProcess ?? "", arguments: [])
    }
    
    @IBAction func buildPicker(_ sender: Any) {
       // To be developed
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
        
        simulatorRadioButton.state = .off
        
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
        physicalDeviceRadioButton.state = .off
        getDeviceButton.isEnabled = false
        languagePopUpButton.isEnabled = true

        if let phoneName = applicationStateHandler.phoneName,
            phoneName != "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.pluginDevice)" {
            phoneComboBox.selectItem(withTitle: phoneName)
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
    }
    
    @IBAction func phys_radio(_ sender: Any) {
        getDeviceButton.isEnabled = true
        languagePopUpButton.isEnabled = false
        simulatorRadioButton.state = .off
        
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
        
        var arguments: [String] = []
        
        if debugCheckbox.state == .on {
            arguments.append("DEBUG=1")
        } else {
            arguments.append("DEBUG=0")
        }
        
        if physicalDeviceRadioButton.state == .on {
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
        if let launchPath = Constants.FilePaths.Bash.sendToIRB {
            let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = { text in
                guard !text.isEmpty else { return }
                DispatchQueue.main.async {
                    self.textViewPrinter.printToTextView(text)
                }
            }
            let arguments = [self.textField.stringValue]
            DispatchQueue.global(qos: .background).async {
                self.commands.executeCommand(at: launchPath, arguments: arguments, outputStream: outputStream)
            }
        }
        textField.stringValue = ""
    }
    
    @IBAction func toggleDebug(_ sender: NSButton) {
        applicationStateHandler.debugState = sender.state.rawValue
    }
    
    @IBAction func stopTask(_ sender:AnyObject) {
       // Need to find solution to stop the task. More control on processes is needed.
//        if isRunning {
//            buildProcess.terminate()
//        }
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
    
    func getSimulatorsCommand() {
        if let launchPath = Constants.FilePaths.Bash.simulators {
            let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = { text in
                let filderedText = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                DispatchQueue.main.async {
                    self.phoneComboBox.addItems(withTitles: filderedText)
                }
            }
            self.commands.executeCommand(at: launchPath, arguments: [], outputStream: outputStream)
        }
    }
    
    func emptyDeviceHandler() {
        if self.phoneComboBox.selectedItem == nil {
            self.deviceListIsEmpty = true
            self.phoneComboBox.highlight(true)
            self.cautionImage.isHidden = false
            let noConnectedDevices = "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.installSimulatorOrPluginDevice)"
            self.phoneComboBox.addItem(withTitle: noConnectedDevices)
            let previousOutput2 = self.textView.string
            self.textView.string = "\(previousOutput2)\n\(noConnectedDevices)"
        } else {
            self.cautionImage.isHidden = true
            self.deviceListIsEmpty = false
        }
    }
    
    func getSimulators() {
        DispatchQueue.main.async {
            self.getDeviceButton.isEnabled = false
            self.isRunning = true
        }
        
        self.getSimulatorsCommand()
        
        DispatchQueue.main.async {
            if let phoneName = self.applicationStateHandler.phoneName {
                self.phoneComboBox.selectItem(withTitle: phoneName)
            }
            self.applicationStateHandler.phoneName = self.phoneComboBox.titleOfSelectedItem
            self.applicationStateHandler.phoneUDID = self.deviceCollector.getDeviceUDID(device: self.phoneComboBox.itemTitle(at: self.phoneComboBox.indexOfSelectedItem))
            self.buildButton.isEnabled = true
            self.isRunning = false
            self.emptyDeviceHandler()
        }
    }
    
    func killIrbSession() {
        commands.executeCommand(at: Constants.FilePaths.Bash.quitIRBSession ?? "", arguments: [])
    }
    
    func statePreservation() {
        applicationStateHandler.simulatorRadioButtonState = simulatorRadioButton.state.rawValue
        applicationStateHandler.physicalButtonState = physicalDeviceRadioButton.state
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
            DispatchQueue.global(qos: .background).async {
                self.commands.executeCommand(at: launchPath, arguments: arguments, outputStream: outputStream)
                DispatchQueue.main.async {
                    self.buildButton.isEnabled = true
                    self.spinner.stopAnimation(self)
                    self.progressBar.stopAnimation(self)
                    self.isRunning = false
                }
            }
        }
    }
    
    func runGeneralIrbSession() {
        self.spinner.startAnimation(self)
        self.progressBar.startAnimation(self)
        if let launchPath = Constants.FilePaths.Bash.createIRBSession {
            let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = {text in
                DispatchQueue.main.async {
                    self.textViewPrinter.printToTextView(text)
                    self.spinner.stopAnimation(self)
                    self.progressBar.stopAnimation(self)
                }
            }
            var arguments: [String] = []
            arguments.append(pathToCalabashFolder)
            if let helpersPath = Constants.FilePaths.Ruby.helpers {
                arguments.append(helpersPath)
            }
            DispatchQueue.global(qos: .background).async {
                self.killIrbSession()
                self.commands.executeCommand(at: launchPath, arguments: arguments, outputStream: outputStream)
            }
        }
    }
}
