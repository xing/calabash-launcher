import Foundation

class PlistOperations {
    
    var plistPath: String
    let fileManager = FileManager.default
    
    public init(defaultPlistPath: String = "/CalabashLauncherSettings.plist") {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        plistPath = documentDirectory.appending(defaultPlistPath)
    }
    
    func create(data : [String : Any]) {
        let someData = NSDictionary(dictionary: data)
        someData.write(toFile: plistPath, atomically: true)
    }
    
    func read(forKey: String) -> ([String], [String]) {
        var plistDictionary: NSDictionary?
        var keysArray = [String]()
        var valuesArray = [String]()
        
        if fileManager.fileExists(atPath: plistPath) {
            plistDictionary = NSDictionary(contentsOfFile: plistPath)
        }
        if let objectsArray = plistDictionary?.mutableArrayValue(forKey: forKey) {
            objectsArray.forEach { dictionary in
                if let dict = dictionary as? NSDictionary, let firstKey = dict.allKeys.first as? String, let firstValue = dict.allValues.first as? String, !dict.allKeys.isEmpty {
                    keysArray.append(firstKey)
                    valuesArray.append(firstValue)
                }
            }
        }
        return(keysArray, valuesArray)
    }
}
