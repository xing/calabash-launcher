import Foundation

class PlistOperations {
    let plistPath: String
    let fileManager = FileManager.default
    let dictionaryKey: String
    
    public init(forKey key: String, defaultPlistPath path: String = "/CalabashLauncherSettings.plist") {
        dictionaryKey = key
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as String
        plistPath = documentDirectory.appending(path)
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
