//
//  PlistOperations.swift
//  Calabash Launcher
//
//  Created by Serghei Moret on 12.10.17.
//  Copyright © 2017 XING. All rights reserved.
//

import Foundation

class PlistOperations {
    func createPlist(data : [String : Any]) {
        let fileManager = FileManager.default
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let path = documentDirectory.appending("/CalabashLauncherSettings.plist")
        
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.removeItem(atPath: path)
        }
        
        let someData = NSDictionary(dictionary: data)
        someData.write(toFile: path, atomically: true)
    }
}
