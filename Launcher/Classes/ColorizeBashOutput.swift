import Cocoa
import Foundation
import AppKit

class ColorizeBashOutput: NSViewController {

var colorCodes:[Int:NSColor] = [
    30: NSColor.black,
    31: NSColor.red,
    32: NSColor.green,
    33: NSColor.yellow,
    34: NSColor.blue,
    35: NSColor.magenta,
    36: NSColor.cyan,
    37: NSColor.white,
    90: NSColor.gray,
    91: NSColor.red,
    92: NSColor.green,
    93: NSColor.yellow,
    94: NSColor.blue,
    95: NSColor.magenta,
    96: NSColor.cyan,
    97: NSColor.white
]

var styleCodes:[Int:NSFont] = [
    0: NSFont.systemFont(ofSize: 15),
    1: NSFont.boldSystemFont(ofSize: 15),
]

func getCode(key: Int) -> Any? {
    if let colorCode = colorCodes[key] {
        return colorCode
    } else if let styleCode = styleCodes[key] {
        return styleCode
    }
    return nil
}



func matchesForRegexInText(regex: String, text: String, global: Bool = false) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: regex) else { return [] }
    let nsString = text as NSString
    let results = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
    
    if !global && results.count == 1 {
        var result: [String] = []
        
        for i in 0..<results[0].numberOfRanges {
            result.append(nsString.substring(with: results[0].range(at: i)))
        }
        
        return result
    }
    else {
        return results.map { nsString.substring(with: $0.range) }
    }
}

struct ANSIGroup {
    var codes:[Int]
    var string:String
    
    func toString() -> String {
        let codeStrings = codes.map { String($0) }
        return "\u{001B}[" + codeStrings.joined(separator: ";") + "m" + string + "\u{001B}[0m"
    }
}

func parseExistingANSI(string: String) -> [ANSIGroup] {
    var results:[ANSIGroup] = []
    
    let matches = matchesForRegexInText(regex: "\\u001B\\[([^m]*)m(.+?)\\u001B\\[0m", text: string, global: true)
    
    for try_mathc in matches {
        let mutliple_match = matchesForRegexInText(regex: "\\u001B\\[([^m]*)m", text: try_mathc, global: true)
        if mutliple_match.count > 2 {
            for i in 0...mutliple_match.count - 2 {
                var multiple_parts = matchesForRegexInText(regex: "\\u001B\\[(\(mutliple_match[i].replacingOccurrences(of: "\u{1B}[", with: "").replacingOccurrences(of: "m", with: "")))m(.+?)\\u001B\\[0m", text: try_mathc)
                
                if multiple_parts.count == 0 {
                    continue
                }
                
                let codes = multiple_parts[1].split {$0 == ";"}.map { String($0) }
                var string = multiple_parts[2].replacingOccurrences(of: "\u{1B}", with: "")
                string.removingRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
                results.append(ANSIGroup(codes: codes.filter { Int($0) != nil }.map { Int($0)! }, string: string))
            }
        } else {
            var parts = matchesForRegexInText(regex: "\\u001B\\[([^m]*)m(.+?)\\u001B\\[0m", text: try_mathc),
            codes = parts[1].split {$0 == ";"}.map { String($0) },
                                                              string = parts[2].replacingOccurrences(of: "\u{1B}", with: "")
            string.removingRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
            results.append(ANSIGroup(codes: codes.filter { Int($0) != nil }.map { Int($0)! }, string: string))
            
        }
    }
    return results
}


    func colorizeTheOutput(outputRawString: String, obj: TasksViewController) {
    
    var myAttributedString:NSMutableAttributedString = NSMutableAttributedString(string: "")
    let parsed_smth = self.parseExistingANSI(string: outputRawString)
    
    var outputString = outputRawString.replacingOccurrences(of: "\u{1B}", with: "")
    
    outputString.removingRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
    myAttributedString = NSMutableAttributedString(string: outputString)
        myAttributedString.setAttributes([.foregroundColor : NSColor.white], range: NSRange(location: 0, length: outputString.count - 1))
    
    if parsed_smth.count > 0 {
        for i in 0 ... parsed_smth.count - 1 {
            for k in 0 ... parsed_smth[i].codes.count - 1 {
                let new_color = self.getCode(key: parsed_smth[i].codes[k])
                
                if parsed_smth[i].string == "" {
                    continue
                }
                
                if outputString.range(of: parsed_smth[i].string) == nil {
                    continue
                }
                
                let index: Int = outputString.distance(from: outputString.startIndex, to: outputString.range(of: parsed_smth[i].string)!.lowerBound)
                let index2: Int = outputString.distance(from: outputString.startIndex, to: outputString.range(of: parsed_smth[i].string)!.upperBound)
                
                if parsed_smth[i].codes[k] == 1 || parsed_smth[i].codes[k] == 0 {
                    myAttributedString.addAttributes([.font: NSFont.boldSystemFont(ofSize: 12)], range: NSRange(location: index, length: index2 - index))
                } else if let newColor = new_color {
                    myAttributedString.setAttributes([.foregroundColor: newColor], range: NSRange(location: index, length: index2 - index))
                }
                
                
            }}
        obj.outputText.textStorage?.append(myAttributedString)
    } else {
        obj.outputText.textStorage?.append(myAttributedString)
    }
}
}
