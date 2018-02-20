import Foundation

class LocalizationHandler {
    
    let applicationStateHandler = ApplicationStateHandler()
    
    func getKey(forString: String) -> [String] {
        
        guard
            let value = parseResponse(response: forString),
            let filePath = applicationStateHandler.filePath?.appendingPathComponent("build/Calabash.app/Frameworks/XNGLocalizedString.framework/en.lproj/Localizable.strings"),
            let stringsDict = NSDictionary(contentsOf: filePath) as? [String: String]
        else { return [] }
        
        return stringsDict.keysForValue(value: value)
    }
    
    private func parseResponse(response: String) -> String? {
        return RegexHandler().matches(for: "\\marked:'(.*?)\\\'", in: response).last
    }
    
}
