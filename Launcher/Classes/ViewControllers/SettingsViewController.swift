import AppKit

class SettingsViewController: NSViewController {
    let applicationStateHandler = ApplicationStateHandler()
    let plistOperations = PlistOperations()
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
    @IBOutlet weak var proceedButton: NSButton!
    @IBOutlet weak var additionalRunParameters: NSTextField!
    @IBOutlet weak var appPathField: NSTextField!
    @IBOutlet weak var commandField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        proceedButton.isHidden = true
        if let filePath = applicationStateHandler.filePath {
            self.fileBrowser.url = filePath
        }
        elements = [
            (linkField1, linkDescriptionField1),
            (linkField2, linkDescriptionField2),
            (linkField3, linkDescriptionField3),
            (linkField4, linkDescriptionField4)
        ]
        
        if let cucumberProfile = plistOperations.readValues(forKey: Constants.Keys.cucumberProfileInfo).first {
            cucumberProfileField.stringValue = cucumberProfile
        }
        
        if let additionalParameters = plistOperations.readValues(forKey: Constants.Keys.additionalFieldInfo).first {
            additionalRunParameters.stringValue = additionalParameters
        }
        
        if let pathToBuild = plistOperations.readValues(forKey: Constants.Keys.pathToBuildInfo).first {
            appPathField.stringValue = pathToBuild
        }
        
        if let command = plistOperations.readValues(forKey: Constants.Keys.commandFieldInfo).first {
            commandField.stringValue = command
        }
        
        let linkArray = plistOperations.readKeys(forKey: Constants.Keys.linkInfo)
        let linkDescriptionArray = plistOperations.readValues(forKey: Constants.Keys.linkInfo)

        for (index, element) in linkArray.enumerated() {
            elements[index].0.stringValue = String(describing: element)
        }

        for (index, element) in linkDescriptionArray.enumerated() {
            elements[index].1.stringValue = String(describing: element)
        }
    }
    
    @IBAction func clickProceedButton(_ sender: Any) {
        self.dismiss(true)
    }
    
    @IBAction func clickResetToDefaults(_ sender: Any) {
        plistOperations.removePlist()
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
        
        let cucumberProfileData = fillDictionary(with: cucumberProfileField.stringValue, for: Constants.Keys.cucumberProfileInfo, on: Constants.Keys.cucumberProfileField)
        let additionalFieldData = fillDictionary(with: additionalRunParameters.stringValue, for: Constants.Keys.additionalFieldInfo, on: Constants.Keys.additionalDataField)
        let pathToBuildFieldData = fillDictionary(with: appPathField.stringValue, for: Constants.Keys.pathToBuildInfo)
        let commandsFieldData = fillDictionary(with: commandField.stringValue, for: Constants.Keys.commandFieldInfo)
        
        var resultingDictionary: [String: Any] = [:]
        
        resultingDictionary.append(dictionary: linkData)
        resultingDictionary.append(dictionary: cucumberProfileData)
        resultingDictionary.append(dictionary: additionalFieldData)
        resultingDictionary.append(dictionary: pathToBuildFieldData)
        resultingDictionary.append(dictionary: commandsFieldData)
        
        plistOperations.create(from: resultingDictionary)
        
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
        if applicationStateHandler.filePath == nil, let controller = storyboard?.instantiateController(withIdentifier: .pathWarning) as? NSViewController {
            presentViewControllerAsModalWindow(controller)
            proceedButton.isHidden = false
        } else {
            self.dismiss(true)
        }
    }
    
    func fillDictionary(with value: String, for key: String, on fieldName: String) -> [String : Any] {
        var data: [String: Any] = [key : []]
        data[key] = [:]
        
        var existingItems =  data[key] as? [[String: String]] ?? []
        
        existingItems.append([fieldName : value])
        data[key] = existingItems
        return data
    }
}

