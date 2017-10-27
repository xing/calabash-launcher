import AppKit

class ApplicationStateHandler {
    
    private let defaults = UserDefaults.standard

    fileprivate enum Keys: String {
        case simulatorRadioButtonState = "simRadioButton"
        case physicalRadioButtonState = "phyRadioButton"
        case isLaunched = "wasLaunched"
        case buildNumber = "buildNumber"
        case filePath = "FilePath"
        case phoneName = "PhoneName"
        case phoneUDID = "PhoneUDID"
        case language = "Language"
        case tag = "Tag"
        case debugState = "DebugCheckbox"
        case cucumberProfile = "cucumberProfile"
    }
    
    var simulatorRadioButtonState: Int {
        get {
            return defaults.integer(forKey: "simRadioButton")
        }
        set {
            defaults.set(newValue, forKey: "simRadioButton")
        }
    }
    
    var physicalButtonState: Int {
        get {
            return defaults.integer(forKey: "phyRadioButton")
        }
        set {
            defaults.set(newValue, forKey:"phyRadioButton")
        }
    }
    
    // todo: does this really need to be handled in the application state handler? it's only used in the view controller
    var isLaunched: Bool {
        get {
            return defaults.bool(forKey: .isLaunched)
        }
        set {
            defaults.set(newValue, forKey: .isLaunched)
        }
    }
    
    var buildNumber: Int {
        get {
            return defaults.integer(forKey: .buildNumber)
        }
        set {
            defaults.set(newValue, forKey: .buildNumber)
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
}
