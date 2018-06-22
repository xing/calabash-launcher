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
    
    /// Returns localization keys for a given value
    /// localizedStringKeys has a priority, if any keys will be found in localizedStrings the function will immediately return
    func localizationKeys(for value: String) -> [String] {
        guard let value = parseResponse(value) else { return [] }
        
        let resultForLocalizedStrings = localizedStringKeys(for: value)
        
        if !resultForLocalizedStrings.isEmpty {
            return resultForLocalizedStrings
        } else {
            return jsonKeys(for: value)
        }
    }
    
    /// This function parses the string and return everything that is between 'marked:' and the last quote.
    /// For example "XNGButton marked:'Login'" will return "Login" string.
    func parseResponse(_ response: String) -> String? {
        return RegexHandler().matches(for: "\\marked:'(.*?)\\\'", in: response).last
    }
    
    /// Transfers dictionary from [String: Any] to [String: String]
    func filterDictionary(_ dictionary: [String: Any]) -> [String: String] {
        let dictionaryWithStrings: [String: String] = dictionary.reduce(into: [:]) { dict, item in
            guard let value = item.value as? String else { return }
            dict[item.key] = value
        }
        return dictionaryWithStrings
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
        func jsonDictionaries(from filePaths: [String]) -> [NSDictionary] {
            return filePaths.compactMap { path -> NSDictionary? in
                guard let path = applicationStateHandler.filePath?.appendingPathComponent(path),
                    let data = try? Data(contentsOf: path, options: .mappedIfSafe),
                    let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves),
                    let jsonDictionary = jsonObject as? NSDictionary else { return nil }
                return jsonDictionary
            }
        }

        func jsonKeys(from dictionaries: [NSDictionary]) -> [String] {
            return dictionaries.map { jsonDictionary -> [String] in
                let jsonKeys = jsonDictionary.allKeys
                let jsonResultsDictionary = flattenValues(for: jsonDictionary, usingKeys: jsonKeys)

                return filterDictionary(jsonResultsDictionary).keysForValue(value)
            }.flatMap { $0 }
        }

        func flattenValues(for jsonDictionary: NSDictionary, usingKeys keys: [Any]) -> [String: Any] {
            let tuples = keys.compactMap { key -> [String: Any]? in
                guard let _jsonDictionary = jsonDictionary[key] as? [String: Any] else { return nil }
                return _jsonDictionary
            }.flatMap { $0 }
            return Dictionary(uniqueKeysWithValues: tuples)
        }

        let dictionaries = jsonDictionaries(from: jsonFilePaths)
        return jsonKeys(from: dictionaries)
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
