import Foundation

class PlistOperations {
    
    var plistPath: String
    let fileManager = FileManager.default
    var dictionaryKey = ""
    
    public init(forKey: String, defaultPlistPath: String = "/CalabashLauncherSettings.plist") {
        dictionaryKey = forKey
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        plistPath = documentDirectory.appending(defaultPlistPath)
    }
    
    func create(data : [String : Any]) {
        let someData = NSDictionary(dictionary: data)
        someData.write(toFile: plistPath, atomically: true)
    }
    
    func read() -> [NSDictionary] {
        var plistDictionary: NSDictionary?
        var keysArray = [NSDictionary]()
        
        if fileManager.fileExists(atPath: plistPath) {
            plistDictionary = NSDictionary(contentsOfFile: plistPath)
        }
        if let objectsArray = plistDictionary?.mutableArrayValue(forKey: dictionaryKey) {
            objectsArray.forEach { dictionary in
                if let dict = dictionary as? NSDictionary, !dict.allKeys.isEmpty {
                    keysArray.append(dict)
                }
            }
        }
        return(keysArray)
    }
    
    func readValues() -> [String] {
        let dictionaryData = self.read()
        let valuesArray = dictionaryData.flatMap { $0.allValues } as? [String]
        return valuesArray ?? [""]
    }
    
    func readKeys() -> [String] {
        let dictionaryData = self.read()
        let keysArray = dictionaryData.flatMap { $0.allKeys } as? [String]
        return keysArray ?? [""]
    }
}
