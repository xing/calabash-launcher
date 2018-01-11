import AppKit

class ApplicationStateHandler {
    
    private let defaults = UserDefaults.standard

    fileprivate enum Keys: String {
        case physicalRadioButtonState = "physicalRadioButtonState"
        case buildName = "buildName"
        case filePath = "filePath"
        case phoneName = "phoneName"
        case phoneUDID = "phoneUDID"
        case language = "testLanguage"
        case tag = "testTag"
        case debugState = "debugCheckboxState"
        case deviceIP = "deviceIP"
        case bundleID = "bundleID"
        case downloadCheckbox = "downloadCheckbox"
    }
    
    var physicalRadioButtonState: Bool {
        get {
            return defaults.bool(forKey: .physicalRadioButtonState)
        }
        set {
            defaults.set(newValue, forKey: .physicalRadioButtonState)
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
    
    var downloadCheckbox: String? {
        get {
            return defaults.string(forKey: .downloadCheckbox)
        }
        set {
            defaults.set(newValue, forKey: .downloadCheckbox)
        }
    }
    
    var deviceIP: String? {
        get {
            return defaults.string(forKey: .deviceIP)
        }
        set {
            defaults.set(newValue, forKey: .deviceIP)
        }
    }
    
    var bundleID: String? {
        get {
            return defaults.string(forKey: .bundleID)
        }
        set {
            defaults.set(newValue, forKey: .bundleID)
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
