import Foundation

class LocalizationHandler {
    
    let applicationStateHandler = ApplicationStateHandler()
    
    func getKeys(for string: String) -> [String] {
        guard
            let value = parseResponse(string),
            let filePath = applicationStateHandler.filePath?.appendingPathComponent("build/Calabash.app/Frameworks/XNGLocalizedString.framework/en.lproj/Localizable.strings"),
            let stringsDict = NSDictionary(contentsOf: filePath) as? [String: String]
        else { return [] }
        
        let resultingKeys = stringsDict.keysForValue(value: value)
        
        if resultingKeys.isEmpty {
            if let path = applicationStateHandler.filePath?.appendingPathComponent("config/text_resources/content/en.json"),
                let data = try? Data(contentsOf: path, options: .mappedIfSafe),
                let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? NSDictionary,
                let enJSON = jsonResult?["en"] as? [String: Any]
            {
                let resultDictionary = filterDictionary(dictionary: enJSON)
                return resultDictionary.keysForValue(value: value)
            }
        }
        return resultingKeys
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
    
    func getAllFiles(for type: String) -> [String] {
        guard let path = applicationStateHandler.filePath?.absoluteString,
            let enumerator:FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: path.replacingOccurrences(of: "file://", with: "")) else { return [] }
        var filePaths = [""]
        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix(type) {
                filePaths.append(element)
            }
        }
        return filePaths
    }
    
}
