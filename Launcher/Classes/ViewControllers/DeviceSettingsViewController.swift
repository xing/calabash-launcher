import AppKit

class DeviceSettingsViewController: NSViewController {
    let applicationStateHandler = ApplicationStateHandler()

    @IBOutlet weak var textField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let deviceIP = applicationStateHandler.deviceIP {
            textField.stringValue = deviceIP
        }
    }
    
    @IBAction func changeTextField(_ sender: Any) {
        applicationStateHandler.deviceIP = textField.stringValue
    }
    
        
    
        
}
