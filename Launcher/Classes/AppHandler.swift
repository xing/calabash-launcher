import Foundation

class AppHandler {
    func applicationRestart() {
        guard let resourcePath = Bundle.main.resourcePath else { exit(0) } // If we don't have a resourcePath, we can't do any restart logic
        let url = URL(fileURLWithPath: resourcePath)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(0)
    }
}
