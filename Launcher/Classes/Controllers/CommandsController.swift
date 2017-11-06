import AppKit
import CommandsCore

class CommandsController {
    let applicationStateHandler = ApplicationStateHandler()
    
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
        DispatchQueue.global(qos: .background).async {
            CommandExecutor(launchPath: launchPath,arguments: [url.absoluteString, filePath], outputStream: outputStream).execute()
        }
    }
    
    func simulatorIsCorrect() -> Bool {
        var result = Bool()
        
        guard let launchPath = Constants.FilePaths.Bash.checkSimulatorType else { return false }
        let outputStream = CommandTextOutputStream()
	
        outputStream.textHandler = { text in
            guard !text.isEmpty else { return }
            
            if text == "Wrong device\n" {
                result = false
            } else {
                result = true
            }
        }
        
        CommandExecutor(launchPath: launchPath,arguments: [], outputStream: outputStream).execute()
        
        return result
    }
}
