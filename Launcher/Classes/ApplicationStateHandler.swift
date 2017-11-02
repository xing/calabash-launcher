import AppKit

class ApplicationStateHandler {
    
    private let defaults = UserDefaults.standard

    fileprivate enum Keys: String {
        case simulatorRadioButtonState = "simulatorRadioButton"
        case buildNumber = "buildNumber"
        case filePath = "filePath"
        case phoneName = "phoneName"
        case phoneUDID = "phoneUDID"
        case language = "testLanguage"
        case tag = "testTag"
        case debugState = "debugCheckboxState"
        case cucumberProfile = "cucumberProfile"
        case additionalRunParameters = "additionalRunParameters"
    }
    
    var simulatorRadioButtonState: Int {
        get {
            return defaults.integer(forKey: .simulatorRadioButtonState)
        }
        set {
            defaults.set(newValue, forKey: .simulatorRadioButtonState)
        }
    }
    
    var buildName: String? {
        get {
            return defaults.string(forKey: .buildName)
        }
        set {
            defaults.set(newValue, forKey: .buildName)
        }
    }
    
    var filePath: URL? {
        get {
            return defaults.url(forKey: .filePath)
        }
        set {
            defaults.set(newValue, forKey: .filePath)
        }
    }
    
    var phoneName: String? {
        get {
            return defaults.string(forKey: .phoneName)
        }
        set {
            defaults.set(newValue, forKey: .phoneName)
        }
    }
    
    var phoneUDID: String? {
        get {
            return defaults.string(forKey: .phoneUDID)
        }
        set {
            defaults.set(newValue, forKey: .phoneUDID)
        }
    }
    
    var language: String? {
        get {
            return defaults.string(forKey: .language)
        }
        set {
            defaults.set(newValue, forKey: .language)
        }
    }
    
    var tag: String? {
        get {
            return defaults.string(forKey: .tag)
        }
        set {
            defaults.set(newValue, forKey: .tag)
        }
    }
    
    var debugState: Int? {
        get {
            return defaults.integer(forKey: .debugState)
        }
        set {
            defaults.set(newValue, forKey: .debugState)
        }
    }
    
    var cucumberProfile: String? {
        get {
            return defaults.string(forKey: .cucumberProfile)
        }
        set {
            defaults.set(newValue, forKey: .cucumberProfile)
        }
    }
    
    var additionalRunParameters: String? {
        get {
            return defaults.string(forKey: .additionalRunParameters)
        }
        set {
            defaults.set(newValue, forKey: .additionalRunParameters)
        }
    }
}

private extension UserDefaults {
    func string(forKey defaultName: ApplicationStateHandler.Keys) -> String? {
        return string(forKey: defaultName.rawValue)
    }

    func integer(forKey defaultName: ApplicationStateHandler.Keys) -> Int {
        return integer(forKey: defaultName.rawValue)
    }

    func bool(forKey defaultName: ApplicationStateHandler.Keys) -> Bool {
        return bool(forKey: defaultName.rawValue)
    }

    func url(forKey defaultName: ApplicationStateHandler.Keys) -> URL? {
        return url(forKey: defaultName.rawValue)
    }

    func set(_ value: Any?, forKey defaultName: ApplicationStateHandler.Keys) {
        set(value, forKey: defaultName.rawValue)
    }

    // It appears UserDefaults doesn't like it when we pass a URL directly
    // into the "Any?" setter, thinking we are passing in a non-property list object.
    func set(_ url: URL?, forKey defaultName: ApplicationStateHandler.Keys) {
        set(url, forKey: defaultName.rawValue)
    }
}
