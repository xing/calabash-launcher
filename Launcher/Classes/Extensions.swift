import AppKit

extension NSColor {
    static var darkAquamarine: NSColor {
        return NSColor(red: 0.18, green: 0.33, blue: 0.43, alpha: 1.0)
    }
    
    static var lightGray: NSColor {
        return NSColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
    }

    static var lightGreen: NSColor {
        return NSColor(red: 0.0, green: 1.0, blue: 0.28, alpha: 1.0)
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func index(of string: String, options: String.CompareOptions = .literal) -> String.Index? {
        return range(of: string, options: options, range: nil, locale: nil)?.lowerBound
    }
    
    func indexes(of string: String, options: String.CompareOptions = .literal) -> [String.Index] {
        var result: [String.Index] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex, locale: nil) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }
    
    mutating func filteringRegexMatches(pattern: String, replaceWith replacement: String = "") {
        self = filteredRegexMatches(pattern: pattern, replaceWith: replacement)
    }

    func filteredRegexMatches(pattern: String, replaceWith replacement: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: count)
            return regex.stringByReplacingMatches(in: self, range: range, withTemplate: replacement)
        } catch {
            return self
        }
    }
}

extension Bundle {
    enum FileType: String {
        case ruby = "rb"
        case bash = "command"
    }
    
    func path(forResource name: String, ofType ext: Bundle.FileType) -> String? {
        return path(forResource: name, ofType: ext.rawValue)
    }
}
