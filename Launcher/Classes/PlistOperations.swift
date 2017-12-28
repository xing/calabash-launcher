import Foundation

class PlistOperations {
    let plistPath: String
    let fileManager = FileManager.default
    let dictionaryKey: String
    
    public init(forKey key: String, defaultPlistPath path: String = "/CalabashLauncherSettings.plist") {
        dictionaryKey = key
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as String
        plistPath = documentDirectory.appending(path)
        
        if let integratedSettingsPath = Bundle.main.path(forResource: "CalabashLauncherSettings", ofType: "plist"), !fileManager.fileExists(atPath: plistPath){
            self.copyFile(atPath: integratedSettingsPath, toPath: documentDirectory.appending(path))
        }
    }
    
    func copyFile(atPath: String, toPath: String) {
        do {
            try fileManager.copyItem(atPath: atPath, toPath: toPath)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
    
    func removePlist() {
        try? fileManager.removeItem(atPath: plistPath)
    }
    
    func create(from dictionary: [String: Any]) {
        let someData = NSDictionary(dictionary: dictionary)
        someData.write(toFile: plistPath, atomically: true)
    }
    
    private func read() -> [NSDictionary] {
        guard
            fileManager.fileExists(atPath: plistPath),
            let dictionary = NSDictionary(contentsOfFile: plistPath) else { return [] }

        return dictionary.mutableArrayValue(forKey: dictionaryKey).flatMap { element -> NSDictionary? in
            guard let dictionary = element as? NSDictionary else { return nil }
            return dictionary
        }
    }
    
    func readValues() -> [String] {
        return read().flatMap { $0.allValues } as? [String] ?? []
    }
    
    func readKeys() -> [String] {
        return read().flatMap { $0.allKeys } as? [String] ?? []
    }
}
