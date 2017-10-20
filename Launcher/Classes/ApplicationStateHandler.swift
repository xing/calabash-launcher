import AppKit

class ApplicationStateHandler {
    
    private let defaults = UserDefaults.standard
    
    var simulatorRadioButtonState: Int? {
        get {
            return defaults.integer(forKey: "simRadioButton")
        }
        set {
            defaults.set(newValue, forKey: "simRadioButton")
        }
    }
    
    var physicalButtonState: NSControl.StateValue? {
        get {
            return NSControl.StateValue(rawValue: defaults.integer(forKey: "phyRadioButton"))
        }
        set {
            defaults.set(newValue, forKey:"phyRadioButton")
        }
    }
    
    // todo: does this really need to be handled in the application state handler? it's only used in the view controller
    var isLaunched: Bool {
        get {
            return defaults.bool(forKey: "wasLaunched")
        }
        set {
            defaults.setValue(newValue, forKey: "wasLaunched")
        }
    }
    
    var buildNumber: Int {
        get {
            return defaults.integer(forKey: "buildNumber")
        }
        set {
            defaults.set(newValue, forKey: "buildNumber")
        }
    }
    
    var filePath: URL? {
        get {
            return defaults.url(forKey: "FilePath")
        }
        set {
            defaults.set(newValue, forKey:"FilePath")
        }
    }
    
    var phoneName: String? {
        get {
            return defaults.string(forKey: "PhoneName")
        }
        set {
            defaults.set(newValue, forKey:"PhoneName")
        }
    }
    
    var phoneUDID: String? {
        get {
            return defaults.string(forKey: "PhoneUDID")
        }
        set {
            defaults.set(newValue, forKey:"PhoneUDID")
        }
    }
    
    var language: String? {
        get {
            return defaults.string(forKey: "Language")
        }
        set {
            defaults.set(newValue, forKey:"Language")
        }
    }
    
    var tag: String? {
        get {
            return defaults.string(forKey: "Tag")
        }
        set {
            defaults.set(newValue, forKey:"Tag")
        }
    }
    
    var debugState: Int? {
        get {
            return defaults.integer(forKey: "DebugCheckbox")
        }
        set {
            defaults.setValue(newValue, forKey: "DebugCheckbox")
        }
    }
    
    var cucumberProfile: String? {
        get {
            return defaults.string(forKey: "cucumberProfile")
        }
        set {
            defaults.set(newValue, forKey:"cucumberProfile")
        }
    }
}
