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
    @IBOutlet weak var switchLanguageButton: NSButton!
    @IBOutlet weak var downloadCheckbox: NSButton!
    @IBOutlet weak var installButton: NSButton!
    
    let localization = Localization()
    let deviceCollector = DeviceCollector()
    let plistOperations = PlistOperations(forKey: Constants.Keys.linkInfo)
    var textViewPrinter: TextViewPrinter!
    @objc dynamic var isRunning = false
    let applicationStateHandler = ApplicationStateHandler()
    let tagsController = TagsController()
    var devices: [String] = []
    var timer: Timer!
    var calabashFolderPath = ""
    var linkInfo: [String] = []
    var commandExecutor: CommandExecutor?
    var isDeviceListEmpty: Bool {
        return phoneComboBox.numberOfItems == 0
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        textField.backgroundColor = .darkGray
        textField.textColor = .white
        let placeholderText = NSMutableAttributedString(string: "Console Input (Beta)".localized)
        placeholderText.setAttributes([.foregroundColor: NSColor.lightGray], range: NSRange(location: 0, length: "Console Input (Beta)".count))
        textField.placeholderAttributedString = placeholderText
        timer = .scheduledTimer(timeInterval: 40, target: self, selector: #selector(cleanupOutput), userInfo: nil, repeats: true);
        populateBuildPicker()
        
        handleRadioButtons(willGetDevice: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textViewPrinter = TextViewPrinter(textView: textView)
        
        let languageValues = Language.all.map { $0.rawValue }
        languagePopUpButton.addItems(withTitles: languageValues)
        
        if let filePath = applicationStateHandler.filePath {
            calabashFolderPath = filePath.absoluteString.replacingOccurrences(of: "file://", with: "")
        } else if let controller = storyboard?.instantiateController(withIdentifier: .settingsWindow) as? NSViewController {
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

        if applicationStateHandler.physicalRadioButtonState {
            getDevices(ofType: .physical)
        } else {
            DispatchQueue.global(qos: .background).async {
                self.getDevices(ofType: .simulator)
            }
        }
        
        if let language = applicationStateHandler.language {
            languagePopUpButton.selectItem(withTitle: language)
        }
        
        if let debugState = applicationStateHandler.debugState {
            debugCheckbox.state = NSControl.StateValue(rawValue: debugState)
        }
        
        if let downloadCheckboxState = applicationStateHandler.downloadCheckbox {
            downloadCheckbox.stringValue = downloadCheckboxState
        }
    }
    
    private func setupTagSelection() {
        tagsController.tags(in: calabashFolderPath).forEach { tag in
            DispatchQueue.main.async {
                self.tagPicker.addItem(withObjectValue: tag)
            }
        }
    }

    func killProcessScreenshot() {
        CommandExecutor(launchPath: Constants.FilePaths.Bash.killProcess ?? "", arguments: []).execute()
    }
    
    @IBAction func clickDownloadButton(_ sender: Any) {
        applicationStateHandler.downloadCheckbox = downloadCheckbox.stringValue
        guard let url = URL(string: plistOperations.readKeys()[buildPicker.indexOfSelectedItem]) else { return }
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.spinner.startAnimation(self)
                self.downloadButton.isEnabled = false
            }
            CommandsController().downloadApp(from: url, textView: self.textView)
            DispatchQueue.main.async {
                self.spinner.stopAnimation(self)
                self.downloadButton.isEnabled = true
            }
        }
    }
    
    @IBAction func clickInstallButton(_ sender: Any) {
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.spinner.startAnimation(self)
                self.installButton.isEnabled = false
            }
            
            var device = ""
            if self.applicationStateHandler.physicalRadioButtonState {
                device = "physical"
            } else {
                device = "simulator"
            }
                
            CommandsController().installApp(textView: self.textView, deviceType: device)
                
            DispatchQueue.main.async {
                self.spinner.stopAnimation(self)
                self.installButton.isEnabled = true
            }
        }
    }
    
    @IBAction func buildPicker(_ sender: Any) {
        applicationStateHandler.buildName = buildPicker.titleOfSelectedItem
        
        let elementsState = buildPicker.titleOfSelectedItem != Constants.Strings.useLocalBuild
        downloadButton.isEnabled = elementsState
        downloadCheckbox.isEnabled = elementsState
    }
    
    @IBAction func clearBufferButton(_ sender: Any) {
        textView.string = ""
    }
    
    @IBAction func settingsButton(_ sender: Any) {
        guard let controller = storyboard?.instantiateController(withIdentifier: .settingsWindow) as? NSViewController else { return }
        presentViewControllerAsSheet(controller)
    }
    
    @IBAction func simulator_radio(_ sender: Any) {
        applicationStateHandler.physicalRadioButtonState = false
        phoneComboBox.removeAllItems()
        handleRadioButtons()
        
        if let phoneName = applicationStateHandler.phoneName,
            phoneName != "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.pluginDevice)" {
            phoneComboBox.selectItem(withTitle: phoneName)
        }
        
        if phoneComboBox.selectedItem == nil {
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let noConnectedSimulators = "\(Constants.Strings.noSimulatorsConnected) \(Constants.Strings.installSimulator)"
            phoneComboBox.addItem(withTitle: noConnectedSimulators)
            let previousOutput = textView.string
            textView.string = "\(previousOutput)\n\(noConnectedSimulators)"
        } else {
            cautionImage.isHidden = true
        }
    }
    
    @IBAction func phys_radio(_ sender: Any) {
        applicationStateHandler.physicalRadioButtonState = true
        phoneComboBox.removeAllItems()
        handleRadioButtons()
        
        if phoneComboBox.selectedItem == nil {
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            phoneComboBox.addItem(withTitle: "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.pluginDevice)")
            getDeviceButton.isEnabled = false
        } else {
            getDeviceButton.isEnabled = true
            cautionImage.isHidden = true
        }
    }
    
    @IBAction func clickTagPicker(_ sender: Any) {
        applicationStateHandler.tag = tagPicker.stringValue
    }
    
    @IBAction func startTask(_ sender:AnyObject) {
        applicationStateHandler.downloadCheckbox = downloadCheckbox.stringValue
        if downloadCheckbox.state == .on, downloadCheckbox.isEnabled {
            guard let url = URL(string: plistOperations.readKeys()[buildPicker.indexOfSelectedItem]) else { return }
            CommandsController().downloadApp(from: url, textView: textView)
        }
        runScript()
    }
    
    @IBAction func textField(_ sender: Any) {
        defer { textField.stringValue = "" }
        guard let launchPath = Constants.FilePaths.Bash.sendToIRB else { return }
        let outputStream = CommandTextOutputStream()
        outputStream.textHandler = { text in
            guard !text.isEmpty else { return }
            DispatchQueue.main.async {
                self.textViewPrinter.printToTextView(text)
            }
        }
        let argument = textField.stringValue
        DispatchQueue.global(qos: .background).async {
            CommandExecutor(launchPath: launchPath, arguments: [argument], outputStream: outputStream).execute()
        }
    }
    
    @IBAction func toggleDebug(_ sender: NSButton) {
        applicationStateHandler.debugState = sender.state.rawValue
    }
    
    @IBAction func stopTask(_ sender:AnyObject) {
        guard let testRunProcess = commandExecutor else { return }
        testRunProcess.terminate()
        commandExecutor = nil
        buildButton.isEnabled = true
        spinner.stopAnimation(self)
        progressBar.stopAnimation(self)
    }

    @IBAction func clickPhoneChooser(_ sender: Any) {
        if !applicationStateHandler.physicalRadioButtonState {
            applicationStateHandler.phoneName = phoneComboBox.titleOfSelectedItem
        }
        applicationStateHandler.phoneUDID = deviceCollector.getDeviceUDID(device: phoneComboBox.itemTitle(at: phoneComboBox.indexOfSelectedItem))
    }
    
    @IBAction func languageSwitchButton(_ sender: Any) {
        localization.changeDefaultLocale(language: languagePopUpButton.title)
    }
    
    @IBAction func languagePopUp(_ sender: Any) {
        applicationStateHandler.language = languagePopUpButton.title
        guard
            let controller = storyboard?.instantiateController(withIdentifier: .languageSettings) as? NSViewController,
            languagePopUpButton.title == Language.other.rawValue else { return }
        presentViewControllerAsModalWindow(controller)
    }

    @objc func cleanupOutput() {
        let maxCharacters = 40_000
        let characterCount = textView.string.count
        
        if characterCount > maxCharacters {
            textView.textStorage?.deleteCharacters(in: NSRange(location: 1, length: characterCount - maxCharacters))
        }
    }
    
    func getDevicesCommand(ofType type: Constants.DeviceType) {
        let path: String?
        
        switch type {
        case .simulator:
            path = Constants.FilePaths.Bash.simulators
        case .physical:
            path = Constants.FilePaths.Bash.physicalDevices
        }
        
        guard let launchPath = path else { return }
        let outputStream = CommandTextOutputStream()
        outputStream.textHandler = { text in
            let filteredText = text.components(separatedBy: "\n")
                .filter { RegexHandler().matches(for: "\\(([^()])*\\) \\[(.*?)\\]", in: $0).isEmpty == false }
            guard !filteredText.isEmpty else { return }
            DispatchQueue.main.async {
                self.phoneComboBox.addItems(withTitles: filteredText)
            }
        }
        CommandExecutor(launchPath: launchPath, arguments: [], outputStream: outputStream).execute()
    }
    
    func emptyDeviceHandler() {
        if isDeviceListEmpty {
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let noConnectedDevices = "\(Constants.Strings.noDevicesConnected) \(Constants.Strings.installSimulatorOrPluginDevice)"
            phoneComboBox.addItem(withTitle: noConnectedDevices)
            let previousOutput = textView.string
            textView.string = "\(previousOutput)\n\(noConnectedDevices)"
            getDeviceButton.isEnabled = false
        } else {
            cautionImage.isHidden = true
        }
    }
    
    func getDevices(ofType type: Constants.DeviceType) {
        DispatchQueue.main.async {
            self.isRunning = true
        }
        
        switch type {
        case .simulator:
            getDevicesCommand(ofType: .simulator)
        case .physical:
            getDevicesCommand(ofType: .physical)
        }
        
        DispatchQueue.main.async {
            if let phoneName = self.applicationStateHandler.phoneName,
                self.phoneComboBox.itemTitles.contains(phoneName),
                type == .simulator
            {
                self.phoneComboBox.selectItem(withTitle: phoneName)
            } else {
                self.phoneComboBox.selectItem(at: 0)
            }
            
            if type == .simulator {
                self.applicationStateHandler.phoneName = self.phoneComboBox.titleOfSelectedItem
            }
            
            self.applicationStateHandler.phoneUDID = self.deviceCollector.getDeviceUDID(device: self.phoneComboBox.titleOfSelectedItem ?? "")
            self.buildButton.isEnabled = true
            self.isRunning = false
            self.emptyDeviceHandler()
        }
    }
    
    func handleRadioButtons(willGetDevice: Bool = true) {
        if applicationStateHandler.physicalRadioButtonState {
            simulatorRadioButton.state = .off
            physicalDeviceRadioButton.state = .on
            getDeviceButton.isEnabled = true
            languagePopUpButton.isEnabled = false
            switchLanguageButton.isEnabled = false
            if willGetDevice {
                spinner.startAnimation(self)
                progressBar.startAnimation(self)
                getDevices(ofType: .physical)
                spinner.stopAnimation(self)
                progressBar.stopAnimation(self)
            }
            guard
                let itemTitle = phoneComboBox.titleOfSelectedItem,
                itemTitle.contains("(null)"),
                let controller = storyboard?.instantiateController(withIdentifier: .deviceUnlock) as? NSViewController else { return }
            presentViewControllerAsModalWindow(controller)
        } else {
            simulatorRadioButton.state = .on
            physicalDeviceRadioButton.state = .off
            getDeviceButton.isEnabled = false
            languagePopUpButton.isEnabled = true
            switchLanguageButton.isEnabled = true
            if willGetDevice {
                spinner.startAnimation(self)
                progressBar.startAnimation(self)
                getDevices(ofType: .simulator)
                spinner.stopAnimation(self)
                progressBar.stopAnimation(self)
            }
        }
    }
    
    func populateBuildPicker() {
        buildPicker.removeAllItems()
        linkInfo = plistOperations.readValues()
        buildPicker.addItems(withTitles: linkInfo)
        buildPicker.addItem(withTitle: Constants.Strings.useLocalBuild)

        if let buildName = applicationStateHandler.buildName, buildPicker.itemTitles.contains(buildName) {
            buildPicker.selectItem(withTitle: buildName)
        } else {
            buildPicker.selectItem(withTitle: Constants.Strings.useLocalBuild)
        }
        
        let elementsState = buildPicker.titleOfSelectedItem != Constants.Strings.useLocalBuild
        downloadButton.isEnabled = elementsState
        downloadCheckbox.isEnabled = elementsState
    }
    
    func quitIrbSession() {
        CommandExecutor(launchPath: Constants.FilePaths.Bash.quitIRBSession ?? "", arguments: []).execute()
    }
    
    func runScript() {
        if isDeviceListEmpty {
            phoneComboBox.highlight(true)
            cautionImage.isHidden = false
            let previousOutput = textView.string
            textView.string = "\(previousOutput)\n\(Constants.Strings.noDevicesConnected) \(Constants.Strings.installSimulatorOrPluginDevice)"
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
        
        arguments.append(calabashFolderPath)
        
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
        
        if let deviceIP = applicationStateHandler.deviceIP,
            let bundleID = applicationStateHandler.bundleID,
            physicalDeviceRadioButton.state == .on,
            !deviceIP.isEmpty {
            arguments.append("export DEVICE_ENDPOINT=http://\(deviceIP):\(Constants.CalabashData.port)")
            arguments.append("export BUNDLE_ID=\(bundleID)")
        } else if physicalDeviceRadioButton.state == .on {
            textViewPrinter.printToTextView(Constants.Strings.wrongDeviceSetup)
            textViewPrinter.printToTextView("\n")
            return
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
                self.commandExecutor = CommandExecutor(launchPath: launchPath, arguments: arguments, outputStream: outputStream)
                self.commandExecutor?.execute()
                
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
        guard let launchPath = Constants.FilePaths.Bash.createIRBSession else { return }
        let outputStream = CommandTextOutputStream()
        outputStream.textHandler = { text in
            DispatchQueue.main.async {
                self.textViewPrinter.printToTextView(text)
                self.spinner.stopAnimation(self)
                self.progressBar.stopAnimation(self)
            }
        }
        var arguments: [String] = []
        arguments.append(calabashFolderPath)
        if let helpersPath = Constants.FilePaths.Ruby.helpers {
            arguments.append(helpersPath)
        }
        DispatchQueue.global(qos: .background).async {
            CommandExecutor(launchPath: launchPath, arguments: arguments, outputStream: outputStream).execute()
        }
    }
}
