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

class LanguageController: NSViewController {
    
    @IBOutlet weak var languagePicker: NSComboBox!
    let applicationStateHandler = ApplicationStateHandler()
    
    override func viewDidAppear() {
        super.viewDidAppear()
        languagePicker.completes = true
        languagePicker.addItems(withObjectValues: NSLocale.availableLocaleIdentifiers)
    }
    
    @IBAction func clickLanguageButton(_ sender: Any) {
        changeLocale(locale: languagePicker.stringValue)
    }
    
    func changeLocale(locale : String) {
        if let simUDID = applicationStateHandler.phoneUdid {
            let arguments = ["Commands", Constants.FilePaths.Bash.changeLang!, simUDID, locale]
            let commands = Commands(arguments: arguments)
            try? commands.run()
        }
    }
        
}
