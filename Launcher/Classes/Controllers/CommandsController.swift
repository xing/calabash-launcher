import AppKit
import CommandsCore

class CommandsController {
    let applicationStateHandler = ApplicationStateHandler()
    let plistHandler = PlistHandler()
    
    func downloadApp(from url: URL, textView: NSTextView) {
        let textViewPrinter = TextViewPrinter(textView: textView)
        guard let launchPath = Constants.FilePaths.Bash.appDownload else { return }
        let outputStream = CommandTextOutputStream()
        outputStream.textHandler = { text in
            DispatchQueue.main.async {
                textViewPrinter.printToTextView(text)
            }
        }

        guard let path = applicationStateHandler.filePath else { return }
        let filePath = path.absoluteString.replacingOccurrences(of: "file://", with: "")
        let pathToMoveBuild = plistHandler.readValues(forKey: Constants.Keys.pathToBuildInfo).first ?? ""
        
        CommandExecutor(launchPath: launchPath, arguments: [url.absoluteString, filePath, pathToMoveBuild], outputStream: outputStream).execute()
    }
    
    func installApp(textView: NSTextView, deviceType: String) {
        let textViewPrinter = TextViewPrinter(textView: textView)
        guard let launchPath = Constants.FilePaths.Bash.appInstall else { return }
        let outputStream = CommandTextOutputStream()
        outputStream.textHandler = { text in
            DispatchQueue.main.async {
                textViewPrinter.printToTextView(text)
            }
        }

        guard let path = applicationStateHandler.filePath else { return }
        let filePath = path.absoluteString.replacingOccurrences(of: "file://", with: "")
        
        if let deviceID = applicationStateHandler.phoneUDID {
            CommandExecutor(launchPath: launchPath, arguments: [deviceID, filePath, deviceType], outputStream: outputStream).execute()
        }
    }
    
    func eraseSimulator(textView: NSTextView) {
        let textViewPrinter = TextViewPrinter(textView: textView)
        guard let launchPath = Constants.FilePaths.Bash.eraseSimulator else { return }
        let outputStream = CommandTextOutputStream()
        outputStream.textHandler = { text in
            DispatchQueue.main.async {
                textViewPrinter.printToTextView(text)
            }
        }
        
        if let deviceID = applicationStateHandler.phoneUDID {
            CommandExecutor(launchPath: launchPath, arguments: [deviceID], outputStream: outputStream).execute()
        }
    }
    
    var isSimulatorCorrect: Bool {
        guard let launchPath = Constants.FilePaths.Bash.checkSimulatorType else { return false }
        let outputStream = CommandTextOutputStream()
	
        var result = false
        outputStream.textHandler = { text in
            guard !text.isEmpty else { return }
            
            if text == "Wrong device\n" {
                result = false
            } else {
                result = true
            }
        }
        
        CommandExecutor(launchPath: launchPath, arguments: [], outputStream: outputStream).execute()
        
        return result
    }
}

