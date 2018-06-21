import Foundation

private extension Collection where Element == String {
    var formattedLocalizationKeys: String {
        return map { "\($0)" }.joined(separator: " / ")
    }
}

class LocalizationHandler {
    
    let applicationStateHandler = ApplicationStateHandler()
    let jsonFilePaths: [String]
    let localizedStringsFilePaths: [String]
    
    init() {
        jsonFilePaths = LocalizationHandler.allFiles(withFileExtension: "json")
        localizedStringsFilePaths = LocalizationHandler.allFiles(withFileExtension: "strings")
    }
    
    func formattedKeys(for string: String) -> String {
        return localizationKeys(for: string).formattedLocalizationKeys
    }
    
    /// Also the header docs could show the priority of keysForLocalizedStrings over keysForJson.
    func localizationKeys(for value: String) -> [String] {
        guard let value = parseResponse(value) else { return [] }
        
        let resultForLocalizedStrings = localizedStringKeys(for: value)
        
        if !resultForLocalizedStrings.isEmpty {
            return resultForLocalizedStrings
        } else {
            return jsonKeys(for: value)
        }
    }
    
    /// Can we add at least some header documentation (with an example) of what this does?
    func parseResponse(_ response: String) -> String? {
        return RegexHandler().matches(for: "\\marked:'(.*?)\\\'", in: response).last
    }
    
    /// what
    func filterDictionary(_ dictionary: [String: Any]) -> [String: String] {
        let letterCount: [String: String] = dictionary.reduce(into: [:]) { dict, item in
            guard let value = item.value as? String else { return }
            dict[item.key] = value
        }
        return letterCount
    }
    
    func localizedStringKeys(for value: String) -> [String] {
        return localizedStringsFilePaths.compactMap { path -> [String]? in
            guard
                let filePath = applicationStateHandler.filePath?.appendingPathComponent(path),
                let stringsDict = NSDictionary(contentsOf: filePath) as? [String: String] else { return nil }
            return stringsDict.keysForValue(value)
            }.flatMap { $0 }
    }
    
    func jsonKeys(for value: String) -> [String] {
        var resultingKeys: [String] = []
        
        jsonFilePaths.forEach { path in
            var jsonResults: [String: Any] = [:]
            
            if let path = applicationStateHandler.filePath?.appendingPathComponent(path),
                let data = try? Data(contentsOf: path, options: .mappedIfSafe),
                let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? NSDictionary,
                let jsonKeys = jsonResult?.allKeys
            {
                jsonKeys.forEach { key in
                    if let jsonDictionary = jsonResult?[key] as? [String: Any] {
                        jsonResults.append(dictionary: jsonDictionary )
                    }
                }
                
                let resultDictionary = filterDictionary(jsonResults)
                
                resultingKeys.append(contentsOf: resultDictionary.keysForValue(value))
            }
        }
        return resultingKeys
    }
    
    static func allFiles(withFileExtension fileExtension: String) -> [String] {
        let applicationStateHandler = ApplicationStateHandler()
        let fileManager = FileManager.default
        
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
