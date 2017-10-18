import Foundation

class DeviceCollector {
    var getSimTask15: Process!
    var outputPipe: Pipe!
    var outputText = ""

    func simulators(completion: @escaping () -> (), output: @escaping (String) -> ()) {
        let taskQueue = DispatchQueue.global(qos: .background)
        
        taskQueue.sync {
            
            let path = Constants.FilePaths.Bash.simulators
            self.getSimTask15 = Process()
            self.getSimTask15.launchPath = path
            
            self.getSimTask15.terminationHandler = { task in
                completion()
            }
            
            captureStandardOutputAndRouteToTextView(self.getSimTask15, completionHandler: output)
            
            self.getSimTask15.launch()
            self.getSimTask15.waitUntilExit()
        }
    }
    
    func captureStandardOutputAndRouteToTextView(_ task: Process, completionHandler handler: @escaping (String) -> ()) {
        
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: .utf8) ?? ""
            
            if !outputString.isEmpty {
                DispatchQueue.main.async {
                    handler(outputString)
                }
            }
            // FIXME: Call a completion handler with an error here?
        }
        self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }
    
    func getDeviceUDID(device : String) -> String {
        // Gets simulator UDID by parcing value between square brackets
        let regex = "\\[(.*?)\\]"
        let match = RegexHandler().matchesForRegexInText(regex: regex, text: device)
        return match.last ?? ""
    }
    
}
