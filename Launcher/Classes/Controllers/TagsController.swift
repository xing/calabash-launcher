//
//  TagsController.swift
//  Calabash Launcher
//
//  Created by Kim Dung-Pham on 11.10.17.
//  Copyright © 2017 XING. All rights reserved.
//

import Foundation
import CommandsCore

class TagsController {
    
    func tags(in folderPath: String) -> [String] {
        let pipe = Pipe()
        let tagsProcess = Process()
        tagsProcess.standardOutput = pipe
        tagsProcess.launchPath = Constants.FilePaths.Bash.tags
        tagsProcess.arguments = [folderPath]
        
        tagsProcess.launch()
        tagsProcess.waitUntilExit()

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        if let outputString = String(data: output, encoding: String.Encoding.utf8), outputString != "" {
            let components = outputString.components(separatedBy: "\n")
            return components
        }
        
        return []
    }
}
