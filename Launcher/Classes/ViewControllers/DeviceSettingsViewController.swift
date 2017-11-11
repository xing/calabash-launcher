import AppKit

class DeviceSettingsViewController: NSViewController {
    let applicationStateHandler = ApplicationStateHandler()

    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var bundleID: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let deviceIP = applicationStateHandler.deviceIP {
            textField.stringValue = deviceIP
        }
        if let bundleIDdata = applicationStateHandler.bundleID {
            bundleID.stringValue = bundleIDdata
        }
    }
    
    @IBAction func changeDeviceIP(_ sender: Any) {
        applicationStateHandler.deviceIP = textField.stringValue
    }
    
    @IBAction func changeBundleIDField(_ sender: Any) {
        applicationStateHandler.bundleID = bundleID.stringValue
    }
}
