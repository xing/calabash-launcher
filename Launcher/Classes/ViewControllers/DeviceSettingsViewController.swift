import AppKit

class DeviceSettingsViewController: NSViewController {
    let applicationStateHandler = ApplicationStateHandler()

    @IBOutlet weak var deviceIPTextField: NSTextField!
    @IBOutlet weak var bundleIDTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let deviceIP = applicationStateHandler.deviceIP {
            deviceIPTextField.stringValue = deviceIP
        }
        if let bundleID = applicationStateHandler.bundleID {
            bundleIDTextField.stringValue = bundleID
        }
    }
    
    @IBAction func changeDeviceIP(_ sender: Any) {
        applicationStateHandler.deviceIP = deviceIPTextField.stringValue
    }
    
    @IBAction func changeBundleID(_ sender: Any) {
        applicationStateHandler.bundleID = bundleIDTextField.stringValue
    }
}
