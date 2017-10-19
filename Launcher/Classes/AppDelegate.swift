import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var buildTaskNew: Process!
    
    @IBAction func closeTheApp(_ sender: AnyObject) {
        killProcessScreenshot()
        NSApplication.shared.terminate(self)
    }

    @IBAction func configurationButton(_ sender: Any) {
        if
            let controller = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "settingswindow")) as? SettingsViewController,
            let contentViewController = NSApplication.shared.mainWindow?.contentViewController,
            contentViewController.presentedViewControllers?.first(where: { $0 is SettingsViewController }) == nil {
            contentViewController.presentViewControllerAsSheet(controller)
        }
    }
    
    func application(application: NSApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(application: NSApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
   
    func shouldSaveApplicationState(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func shouldRestoreApplicationState(_ sender: NSApplication) -> Bool {
        return true
    }
    func applicationWillTerminate(_ notification: Notification) {
        killProcessScreenshot()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        killProcessScreenshot()
        return true
    }
    
    func killProcessScreenshot() {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        
        taskQueueNew.sync {
            let path = Constants.FilePaths.Bash.killProcess
            self.buildTaskNew = Process()
            self.buildTaskNew.launchPath = path
            self.buildTaskNew.launch()
            self.buildTaskNew.waitUntilExit()
        }
    }
}
