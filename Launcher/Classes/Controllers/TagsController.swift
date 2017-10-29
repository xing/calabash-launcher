import CommandsCore

class TagsController {
    
    func tags(in folderPath: String) -> [String] {
        var tags = [String]()
        
        if let launchPath = Constants.FilePaths.Bash.tags {
            let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = {text in
                tags.append(contentsOf: text.components(separatedBy: "\n").filter { !$0.isEmpty })
            }
            CommandsCore.CommandExecutor(launchPath: launchPath, arguments: [folderPath], outputStream: outputStream).execute()
        }
        return tags
    }
}
