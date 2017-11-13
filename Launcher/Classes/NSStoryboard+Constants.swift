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
    static let settingsWindow = "settingswindow".sceneIdentifier
    static let warningWindow = "warningwindow".sceneIdentifier
    static let languageSettings = "languagesettings".sceneIdentifier
    static let wrongSimulator = "wrongSimulatorWindow".sceneIdentifier
    static let pathWarning = "pathWarning".sceneIdentifier
}
