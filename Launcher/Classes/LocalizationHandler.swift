import Foundation

class LocalizationHandler {
    
    let applicationStateHandler = ApplicationStateHandler()
    
    func getKeys(for string: String) -> [String] {
        
        guard
            let value = parseResponse(string),
            let filePath = applicationStateHandler.filePath?.appendingPathComponent("build/Calabash.app/Frameworks/XNGLocalizedString.framework/en.lproj/Localizable.strings"),
            let stringsDict = NSDictionary(contentsOf: filePath) as? [String: String]
        else { return [] }
        
        return stringsDict.keysForValue(value: value)
    }
    
    func parseResponse(_ response: String) -> String? {
        return RegexHandler().matches(for: "\\marked:'(.*?)\\\'", in: response).last
    }
    
}
