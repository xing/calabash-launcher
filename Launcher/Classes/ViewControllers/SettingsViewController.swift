import AppKit

class SettingsViewController: NSViewController {
    let applicationStateHandler = ApplicationStateHandler()
    let plistHandler = PlistHandler()
    var pathChanged = false
    var hasWarnings = false
    var singleLinkData: [String: String] = [:]
    var elements: [(NSTextField, NSTextField)] = []

    @IBOutlet var fileBrowser: NSPathControl!
    @IBOutlet weak var cucumberProfileField: NSTextField!
    @IBOutlet weak var linkField1: NSTextField!
    @IBOutlet weak var linkField2: NSTextField!
    @IBOutlet weak var linkField3: NSTextField!
    @IBOutlet weak var linkField4: NSTextField!
    @IBOutlet weak var linkDescriptionField1: NSTextField!
    @IBOutlet weak var linkDescriptionField2: NSTextField!
    @IBOutlet weak var linkDescriptionField3: NSTextField!
    @IBOutlet weak var linkDescriptionField4: NSTextField!
    @IBOutlet weak var warningField: NSTextField!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var additionalRunParameters: NSTextField!
    @IBOutlet weak var appPathField: NSTextField!
    @IBOutlet weak var commandField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let filePath = applicationStateHandler.filePath {
            self.fileBrowser.url = filePath
        }
        elements = [
            (linkField1, linkDescriptionField1),
            (linkField2, linkDescriptionField2),
            (linkField3, linkDescriptionField3),
            (linkField4, linkDescriptionField4)
        ]
        
        if let cucumberProfile = plistHandler.readValues(forKey: Constants.Keys.cucumberProfileInfo).first {
            cucumberProfileField.stringValue = cucumberProfile
        }
        
        if let additionalParameters = plistHandler.readValues(forKey: Constants.Keys.additionalFieldInfo).first {
            additionalRunParameters.stringValue = additionalParameters
        }
        
        if let pathToBuild = plistHandler.readValues(forKey: Constants.Keys.pathToBuildInfo).first {
            appPathField.stringValue = pathToBuild
        }
        
        if let command = plistHandler.readValues(forKey: Constants.Keys.commandFieldInfo).first {
            commandField.stringValue = command
        }
        
        let linkKeys = plistHandler.readKeys(forKey: Constants.Keys.linkInfo)
        let linkValues = plistHandler.readValues(forKey: Constants.Keys.linkInfo)

        for (index, element) in linkKeys.enumerated() {
            elements[index].0.stringValue = String(describing: element)
        }

        for (index, element) in linkValues.enumerated() {
            elements[index].1.stringValue = String(describing: element)
        }
    }
    
    @IBAction func clickResetToDefaults(_ sender: Any) {
        plistHandler.removePlist()
        AppHandler().restartApplication()
    }
    
    @IBAction func clickSaveButton(_ sender: Any) {
        var linkData: [String: Any] = [Constants.Keys.linkInfo : []]
        linkData[Constants.Keys.linkInfo] = [:]
        hasWarnings = false
        var warningState = false
        var existingLinkItems = linkData[Constants.Keys.linkInfo] as? [[String: String]] ?? []
        
        for element in elements {
            (singleLinkData, warningState) = getLinkDataFrom(linkField: element.0, linkDescriptionField: element.1)

            if !warningState {
                existingLinkItems.append(singleLinkData)
            } else {
                hasWarnings = true
            }
        }
        
        if hasWarnings {
            existingLinkItems = [[:]]
        } else {
            linkData[Constants.Keys.linkInfo] = existingLinkItems
        }
        
        let cucumberProfileData = appendToDictionary(using: cucumberProfileField.stringValue, for: Constants.Keys.cucumberProfileInfo)
        let additionalFieldData = appendToDictionary(using: additionalRunParameters.stringValue, for: Constants.Keys.additionalFieldInfo)
        let pathToBuildFieldData = appendToDictionary(using: appPathField.stringValue, for: Constants.Keys.pathToBuildInfo)
        let commandsFieldData = appendToDictionary(using: commandField.stringValue, for: Constants.Keys.commandFieldInfo)
        
        var resultingDictionary: [String: Any] = [:]
        
        resultingDictionary.append(dictionary: linkData)
        resultingDictionary.append(dictionary: cucumberProfileData)
        resultingDictionary.append(dictionary: additionalFieldData)
        resultingDictionary.append(dictionary: pathToBuildFieldData)
        resultingDictionary.append(dictionary: commandsFieldData)
        
        plistHandler.create(from: resultingDictionary)
        
        // Reload build picker to get new elements
        if
            let tabViewController = NSApplication.shared.mainWindow?.contentViewController as? NSTabViewController,
            let tasksViewController = tabViewController.childViewControllers.first as? TasksViewController {
            tasksViewController.populateBuildPicker()
        }
        
        // Restart app after new path is available. Close Settings and save settings otherwise.
        if pathChanged {
            AppHandler().restartApplication()
        } else if !hasWarnings {
            emptyPathHandling()
        }
    }
    
    @IBAction func clickFileBrowser(_ sender: Any) {
        pathChanged = true
        if let pathItem = fileBrowser.clickedPathItem {
            fileBrowser.url = pathItem.url
        }
        applicationStateHandler.filePath = fileBrowser.url
    }
    
    @IBAction func clickCloseButton(_ sender: Any) {
        emptyPathHandling()
    }
    
    func getLinkDataFrom(linkField : NSTextField, linkDescriptionField : NSTextField) -> ([String: String], Bool) {
        var hasWarnings: Bool = false
        var resultDict: [String: String] = [:]
        if !linkField.stringValue.isEmpty && !linkDescriptionField.stringValue.isEmpty {
            resultDict = [linkField.stringValue : linkDescriptionField.stringValue]
        } else if linkField.stringValue.isEmpty && linkDescriptionField.stringValue.isEmpty {
            hasWarnings = false
        } else {
            hasWarnings = true
            linkField.isHighlighted = true
            linkDescriptionField.isHighlighted = true
            warningField.stringValue = "Please fill 'Description' field(s)"
        }
        return (resultDict, hasWarnings)
    }
    
    func emptyPathHandling() {
        guard
            applicationStateHandler.filePath == nil,
            let window = view.window else {
                self.dismiss(true)
                return
        }

        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "The path to the test folder is not set or is incorrect.".localized,
            NSLocalizedRecoverySuggestionErrorKey: "Please choose the path to your calabash test folder.".localized,
            NSLocalizedRecoveryOptionsErrorKey: ["Choose Test Folder…".localized, "Close Anyway".localized]
        ]
        let error = NSError(domain: "calabash", code: 0, userInfo: userInfo)
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: window) { [weak self] response in
            switch response {
            case .alertFirstButtonReturn:
                self?.showOpenPanel()
            case .alertSecondButtonReturn:
                self?.dismiss(true)
            default:
                print("(Unhandled option)")
            }
        }
    }
    
    func appendToDictionary(using value: String, for key: String) -> [String : Any] {
        var data: [String: Any] = [key : []]
        data[key] = [:]
        
        var existingItems = data[key] as? [[String: String]] ?? []
        
        existingItems.append([key : value])
        data[key] = existingItems
        return data
    }

    private func showOpenPanel() {
        guard let window = view.window else { return }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.resolvesAliases = true
        panel.title = "Choose a path".localized
        panel.prompt = "Choose".localized
        panel.beginSheetModal(for: window) { [weak self] result in
            panel.orderOut(self)
            guard result ==  NSApplication.ModalResponse.OK else { return }

            let url = panel.urls.first
            self?.fileBrowser.url = url
            self?.applicationStateHandler.filePath = url
            self?.pathChanged = true
        }
    }

}

