import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var buildTaskNew: Process!
    
    @IBAction func closeTheApp(_ sender: AnyObject) {
        killProcessScreenshot()
        NSApplication.shared.terminate(self)
    }

    @IBAction func configurationButton(_ sender: Any) {
        guard
            let controller = NSStoryboard(name: .main, bundle: nil).instantiateController(withIdentifier: .settingsWindow) as? SettingsViewController,
            let contentViewController = NSApplication.shared.mainWindow?.contentViewController,
            contentViewController.presentedViewControllers?.first(where: { $0 is SettingsViewController }) == nil else { return }
        contentViewController.presentViewControllerAsSheet(controller)
    }
    
    @IBAction func resetUserDefaults(_ sender: Any) {
        // Reset UserDefaults
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            AppHandler().restartApplication()
        } else if
            let controller = NSStoryboard(name: .main, bundle: nil).instantiateController(withIdentifier: .warningWindow) as? NSViewController,
            let contentViewController = NSApplication.shared.mainWindow?.contentViewController,
            contentViewController.presentedViewControllers?.first(where: { $0 is SettingsViewController }) == nil {
                contentViewController.presentViewControllerAsModalWindow(controller)
        }
    }
    
    @IBAction func runTests(_ sender: Any) {
        guard
            let tabViewController = NSApplication.shared.mainWindow?.contentViewController as? NSTabViewController,
            let tasksViewController = tabViewController.childViewControllers.first as? TasksViewController else { return }
        tasksViewController.runScript()
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
        
        taskQueueNew.sync { [weak self] in
            guard let strongSelf = self else { return }
            let path = Constants.FilePaths.Bash.killProcess
            strongSelf.buildTaskNew = Process()
            strongSelf.buildTaskNew.launchPath = path
            strongSelf.buildTaskNew.launch()
            strongSelf.buildTaskNew.waitUntilExit()
        }
    }
}
