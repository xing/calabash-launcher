//
//  LanguageController.swift
//  Calabash Launcher
//
//  Created by Serghei Moret on 16.10.17.
//  Copyright © 2017 XING. All rights reserved.
//

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
