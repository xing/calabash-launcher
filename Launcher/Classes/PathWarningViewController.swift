//
//  PathWarningViewController.swift
//  Calabash Launcher
//
//  Created by Serghei Moret on 13.10.17.
//  Copyright © 2017 XING. All rights reserved.
//

import Cocoa
import Foundation
import AppKit

class PathWarningViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func okButton(_ sender: Any) {
        self.dismiss(true)
    }
}
