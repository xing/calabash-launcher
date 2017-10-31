import AppKit
import CommandsCore

class CommandsController {
    let applicationStateHandler = ApplicationStateHandler()
    
    func downloadAppFromLink(link: String, textView: NSTextView) {
        let textViewPrinter = TextViewPrinter(textView: textView)
        if let launchPath = Constants.FilePaths.Bash.appDownload {
            let outputStream = CommandTextOutputStream()
            outputStream.textHandler = {text in
                DispatchQueue.main.async {
                    textViewPrinter.printToTextView(text)
                }
            }
            let commands = CommandExecutor()
            if let path = applicationStateHandler.filePath {
                let filePath = path.absoluteString.replacingOccurrences(of: "file://", with: "")
                commands.executeCommand(at: launchPath, arguments: [link, filePath], outputStream: outputStream)
            }
        }
    }
}
