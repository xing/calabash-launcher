import Foundation

class LocalizationHandler {
    
    let applicationStateHandler = ApplicationStateHandler()
    let fileManager = FileManager.default
    
    func keys(for string: String) -> [String] {
        guard let value = parseResponse(string) else { return [] }
        
        let resultForLocalizedStrings = keysForLocalizedStrings(value: value)
        
        if !resultForLocalizedStrings.isEmpty {
            return resultForLocalizedStrings
        } else {
            return keysForJson(value: value)
        }
    }
    
    func parseResponse(_ response: String) -> String? {
        return RegexHandler().matches(for: "\\marked:'(.*?)\\\'", in: response).last
    }
    
    func filterDictionary(dictionary: [String: Any]) -> [String: String] {
        let letterCount: [String: String] = dictionary.reduce(into: [:]) { dict, item in
            guard let value = item.value as? String else {return}
            dict[item.key] = value
        }
        return letterCount
    }
    
    func keysForLocalizedStrings(value: String) -> [String] {
        let localizedStringsFilePaths = allFiles(withFileExtension: "strings")
        var resultingKeys: [String] = []
        
        localizedStringsFilePaths.forEach() { path in
            if let filePath = applicationStateHandler.filePath?.appendingPathComponent(path),
                let stringsDict = NSDictionary(contentsOf: filePath) as? [String: String]
            {
                resultingKeys.append(contentsOf: stringsDict.keysForValue(value: value))
            }
        }
        return resultingKeys
    }
    
    func keysForJson(value: String) -> [String] {
        var resultingKeys: [String] = []
        let jsonFilePaths = allFiles(withFileExtension: "json")
        
        jsonFilePaths.forEach() { path in
            var jsonResults: [String: Any] = [:]
            
            if let path = applicationStateHandler.filePath?.appendingPathComponent(path),
                let data = try? Data(contentsOf: path, options: .mappedIfSafe),
                let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? NSDictionary,
                let jsonKeys = jsonResult?.allKeys
            {
                jsonKeys.forEach() { key in
                    if let jsonDictionary = jsonResult?[key] as? [String: Any] {
                        jsonResults.append(dictionary: jsonDictionary )
                    }
                }
                
                let resultDictionary = filterDictionary(dictionary: jsonResults)
                
                resultingKeys.append(contentsOf: resultDictionary.keysForValue(value: value))
            }
        }
        return resultingKeys
    }
    
    func allFiles(withFileExtension fileExtension: String) -> [String] {
        guard let path = applicationStateHandler.filePath?.absoluteString,
            let enumerator = fileManager.enumerator(atPath: path.replacingOccurrences(of: "file://", with: "")) else { return [] }
        var filePaths = [""]
        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix(fileExtension) {
                filePaths.append(element)
            }
        }
        return filePaths
    }
    
}
