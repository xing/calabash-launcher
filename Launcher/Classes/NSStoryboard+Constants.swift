import AppKit

fileprivate extension String {
    var name: NSStoryboard.Name {
        return NSStoryboard.Name(rawValue: self)
    }

    var sceneIdentifier: NSStoryboard.SceneIdentifier {
        return NSStoryboard.SceneIdentifier(rawValue: self)
    }
}

extension NSStoryboard.Name {
    static let main = "Main".name
}

extension NSStoryboard.SceneIdentifier {
    static let
    settingsWindow = "settingswindow".sceneIdentifier,
    warningWindow = "warningwindow".sceneIdentifier,
    languageSettings = "languagesettings".sceneIdentifier,
    wrongSimulator = "wrongSimulatorWindow".sceneIdentifier,
    pathWarning = "pathWarning".sceneIdentifier,
    deviceUnlock = "deviceUnlock".sceneIdentifier
}
