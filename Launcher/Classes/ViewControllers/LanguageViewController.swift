import Cocoa
import Foundation
import AppKit
import CommandsCore

class LanguageViewController: NSViewController {
    
    @IBOutlet weak var languagePicker: NSComboBox!
    let applicationStateHandler = ApplicationStateHandler()
    let language = Localization()
    
    override func viewDidAppear() {
        super.viewDidAppear()
        languagePicker.completes = true
        languagePicker.addItems(withObjectValues: NSLocale.availableLocaleIdentifiers)
    }
    
    @IBAction func clickLanguageButton(_ sender: Any) {
        language.changeLocale(locale: languagePicker.stringValue)
    }
}
