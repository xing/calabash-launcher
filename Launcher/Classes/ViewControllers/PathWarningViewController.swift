import AppKit

class PathWarningViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func okButton(_ sender: Any) {
        self.dismiss(true)
    }
}
