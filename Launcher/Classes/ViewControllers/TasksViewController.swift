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
    @IBOutlet weak var downloadButton: NSButton!
    
    let localization = Localization()
    let deviceCollector = DeviceCollector()
    let plistOperations = PlistOperations(forKey: Constants.Keys.linkInfo)
    var textViewPrinter: TextViewPrinter!
    var deviceListIsEmpty = false
    @objc dynamic var isRunning = false
    let applicationStateHandler = ApplicationStateHandler()
    let tagsController = TagsController()
    var devices = [""]
    var timer: Timer!
    var pathToCalabashFolder = ""
    var linkInfoArray = [""]
    var testRun: Process?
    var isDeviceListEmpty: Bool {
        return phoneComboBox.numberOfItems == 0
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        textField.backgroundColor = .darkAquamarine
        textField.textColor = .white
        let placeholderText = NSMutableAttributedString(string: "Console Input (Beta)")
        placeholderText.setAttributes([.foregroundColor: NSColor.lightGray], range: NSRange(location: 0, length: "Console Input (Beta)".count))
        textField.placeholderAttributedString = placeholderText
        timer = .scheduledTimer(timeInterval: 40, target: self, selector: #selector(self.limitOfChars), userInfo: nil, repeats: true);
        getValuesForBuildPicker()
        // Disable these elements for the moment, as it cannot work for people outside XING
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
        quitIrbSession()
        runGeneralIrbSession()
        DispatchQueue.global(qos: .background).async {
            self.setupTagSelection()
            if let tag = self.applicationStateHandler.tag {
                DispatchQueue.main.async {
                    self.tagPicker.selectItem(withObjectValue: tag)
                }
            }
        }

        simulatorRadioButton.state = NSControl.StateValue(rawValue: applicationStateHandler.simulatorRadioButtonState)

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
        CommandExecutor(launchPath: Constants.FilePaths.Bash.killProcess ?? "", arguments: []).execute()
    }
    
    @IBAction func clickDownloadButton(_ sender: Any) {
        guard let url = URL(string: plistOperations.readKeys()[buildPicker.indexOfSelectedItem]) else { return }
        CommandsController().downloadApp(from: url, textView: textView)
    }
    
    @IBAction func buildPicker(_ sender: Any) {
       applicationStateHandler.buildName = buildPicker.titleOfSelectedItem
        if buildPicker.titleOfSelectedItem == Constants.Strings.useLocalBuild {
            downloadButton.isEnabled = false
        } else {
            downloadButton.isEnabled = true
        }
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
        runScript()
    }
    
    @IBAction func textField(_ sender: Any) {
        if let launchPath = Constants.FilePaths.Bash.sendToIRB {
            let outputStream = CommandTextOutputStream()
            outputStream.textHandler = { text in
                guard !text.isEmpty else { return }
                DispatchQueue.main.async {
                    self.textViewPrinter.printToTextView(text)
                }
            }
            let arguments = [self.textField.stringValue]
            DispatchQueue.global(qos: .background).async {
                CommandExecutor(launchPath: launchPath, arguments: arguments, outputStream: outputStream).execute()
            }
        }
        textField.stringValue = ""
    }
    
    @IBAction func toggleDebug(_ sender: NSButton) {
        applicationStateHandler.debugState = sender.state.rawValue
    }
    
    @IBAction func stopTask(_ sender:AnyObject) {
        if let testRunProcess = testRun {
            testRunProcess.terminate()
            testRun = nil
            self.buildButton.isEnabled = true
            self.spinner.stopAnimation(self)
            self.progressBar.stopAnimation(self)
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
    
    func getSimulatorsCommand() {
        if let launchPath = Constants.FilePaths.Bash.simulators {
            let outputStream = CommandTextOutputStream()
            outputStream.textHandler = { text in
                let filderedText = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                DispatchQueue.main.async {
                    self.phoneComboBox.addItems(withTitles: filderedText)
                }
            }
            CommandExecutor(launchPath: launchPath, arguments: [], outputStream: outputStream).execute()
        }
    }
    
    func emptyDeviceHandler() {
        if isDeviceListEmpty {
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
            if let phoneName = self.applicationStateHandler.phoneName, self.phoneComboBox.itemTitles.contains(phoneName) {
                self.phoneComboBox.selectItem(withTitle: phoneName)
            } else {
                self.phoneComboBox.selectItem(at: 0)
            }
            
            self.applicationStateHandler.phoneName = self.phoneComboBox.titleOfSelectedItem
            self.applicationStateHandler.phoneUDID = self.deviceCollector.getDeviceUDID(device: self.phoneComboBox.titleOfSelectedItem ?? "")
            self.buildButton.isEnabled = true
            self.isRunning = false
            self.emptyDeviceHandler()
        }
    }
    
    func getValuesForBuildPicker() {
        buildPicker.removeAllItems()
        linkInfoArray = plistOperations.readValues()
        buildPicker.addItems(withTitles: linkInfoArray)
        buildPicker.addItem(withTitle: Constants.Strings.useLocalBuild)

        if let buildName = applicationStateHandler.buildName, buildPicker.itemTitles.contains(buildName) {
            buildPicker.selectItem(withTitle: buildName)
        } else {
            buildPicker.selectItem(withTitle: Constants.Strings.useLocalBuild)
        }
        
        if buildPicker.titleOfSelectedItem == Constants.Strings.useLocalBuild {
            downloadButton.isEnabled = false
        } else {
            downloadButton.isEnabled = true
        }
    }
    
    func quitIrbSession() {
        CommandExecutor(launchPath: Constants.FilePaths.Bash.quitIRBSession ?? "", arguments: []).execute()
    }
    
    func statePreservation() {
        applicationStateHandler.simulatorRadioButtonState = simulatorRadioButton.state.rawValue
        applicationStateHandler.tag = tagPicker.stringValue
    }
    
    func runScript() {
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
        
        arguments.append("DEVICE_TARGET=\(applicationStateHandler.phoneUDID ?? "")")
        
        arguments.append(pathToCalabashFolder)
        
        if let cucumberProfile = applicationStateHandler.cucumberProfile, !cucumberProfile.isEmpty {
            arguments.append("-p \(cucumberProfile)")
        }
        
        // We still need an arugment to be passed, otherwise bash variable order will be spoiled
        if !tagPicker.stringValue.isEmpty {
            arguments.append("--t @\(tagPicker.stringValue)")
        } else {
            arguments.append("")
        }
        
        if let additionalRunParameter = applicationStateHandler.additionalRunParameters, !additionalRunParameter.isEmpty {
            arguments.append("export \(additionalRunParameter)")
        } else {
            arguments.append("")
        }
        
        buildButton.isEnabled = false
        
        isRunning = true
        spinner.startAnimation(self)
        progressBar.startAnimation(self)
        
        if let launchPath = Constants.FilePaths.Bash.buildScript {
            let outputStream = CommandTextOutputStream()
            outputStream.textHandler = { text in
                DispatchQueue.main.async {
                    self.textViewPrinter.printToTextView(text)
                }
            }
            DispatchQueue.global(qos: .background).async {
                self.testRun = Process()
                if let testProcess = self.testRun {
                    CommandExecutor(launchPath: launchPath, arguments: arguments, outputStream: outputStream).execute(process: testProcess)
                }
                
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
            let outputStream = CommandTextOutputStream()
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
                CommandExecutor(launchPath: launchPath, arguments: arguments, outputStream: outputStream).execute()
            }
        }
    }
}
