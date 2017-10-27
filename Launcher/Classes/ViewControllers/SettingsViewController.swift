import AppKit

class SettingsViewController: NSViewController {
    let applicationStateHandler = ApplicationStateHandler()
    let plistOperations = PlistOperations()
    var linkData: [String: Any] = ["items" : []]
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
        
        if let cucumberProfile = applicationStateHandler.cucumberProfile {
            cucumberProfileField.stringValue = cucumberProfile
        }
        
        if let additionalParameters = applicationStateHandler.additionalRunParameters {
            additionalRunParameters.stringValue = additionalParameters
        }
    }
    
    @IBAction func clickProceedButton(_ sender: Any) {
        self.dismiss(true)
    }
    
    @IBAction func clickSaveButton(_ sender: Any) {
        linkData["items"] = [:]
        hasWarnings = false
        var warningState = false
        var existingItems = linkData["items"] as? [[String: String]] ?? []
        
        for element in elements {
            (singleLinkData, warningState) = getLinkDataFrom(linkField: element.0, linkDescriptionField: element.1)

            if !warningState {
                existingItems.append(singleLinkData)
            } else {
                hasWarnings = true
            }
        }
        
        if hasWarnings {
            existingItems = [[:]]
        } else {
            linkData["items"] = existingItems
            plistOperations.createPlist(data: linkData)
        }
        
        applicationStateHandler.cucumberProfile = cucumberProfileField.stringValue
        applicationStateHandler.additionalRunParameters = additionalRunParameters.stringValue
        
        // Restart APP after new path is available. Close Settings and save settings otherwise.
        if pathChanged {
            AppHandler().restartApplication()
        } else if !hasWarnings {
            emptyPathHandling()
        }
    }
    
    @IBAction func clickFileBrowser(_ sender: Any) {
        pathChanged = true
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
        if applicationStateHandler.filePath == nil, let controller = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "pathWarning")) as? NSViewController {
            presentViewControllerAsModalWindow(controller)
            proceedButton.isHidden = false
        } else {
            self.dismiss(true)
        }
    }

}

