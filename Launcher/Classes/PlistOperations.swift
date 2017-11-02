import Foundation

class PlistOperations {
    func createPlist(data : [String : Any]) {
        let fileManager = FileManager.default
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as String
        let path = documentDirectory.appending("/CalabashLauncherSettings.plist")
        
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.removeItem(atPath: path)
        }
        
        let someData = NSDictionary(dictionary: data)
        someData.write(toFile: path, atomically: true)
    }
}
