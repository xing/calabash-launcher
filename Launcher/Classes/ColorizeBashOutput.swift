import AppKit

class ColorizeBashOutput: NSViewController {

    var colorCodes: [Int: NSColor] = [
        30: .black,
        31: .red,
        32: .green,
        33: .yellow,
        34: .blue,
        35: .magenta,
        36: .cyan,
        37: .white,
        90: .gray,
        91: .red,
        92: .green,
        93: .yellow,
        94: .blue,
        95: .magenta,
        96: .cyan,
        97: .white
    ]

    var styleCodes: [Int: NSFont] = [
        0: .systemFont(ofSize: 15),
        1: .boldSystemFont(ofSize: 15),
        ]

    func getCode(key: Int) -> Any? {
        if let colorCode = colorCodes[key] {
            return colorCode
        } else if let styleCode = styleCodes[key] {
            return styleCode
        }
        return nil
    }

    struct ANSIGroup {
        var codes: [Int]
        var string: String
    }

    func parseExistingANSI(string: String) -> [ANSIGroup] {
        var results: [ANSIGroup] = []
        let regex = RegexHandler()
        let matches = regex.matches(for: "\\u001B\\[([^m]*)m(.+?)\\u001B\\[0m", in: string, global: true)

        for try_mathc in matches {
            let mutliple_match = regex.matches(for: "\\u001B\\[([^m]*)m", in: try_mathc, global: true)
            if mutliple_match.count > 2 {
                for i in 0...mutliple_match.count - 2 {
                    var multiple_parts = regex.matches(for: "\\u001B\\[(\(mutliple_match[i].replacingOccurrences(of: "\u{1B}[", with: "").replacingOccurrences(of: "m", with: "")))m(.+?)\\u001B\\[0m", in: try_mathc)

                    if multiple_parts.count == 0 {
                        continue
                    }

                    let codes = multiple_parts[1].split {$0 == ";"}.map { String($0) }
                    var string = multiple_parts[2]
                        .replacingOccurrences(of: "\u{1B}", with: "")
                    string.removingRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
                    results.append(ANSIGroup(codes: codes.flatMap { Int($0) }, string: string))
                }
            } else {
                var parts = regex.matches(for: "\\u001B\\[([^m]*)m(.+?)\\u001B\\[0m", in: try_mathc),
                codes = parts[1].split {$0 == ";"}.map { String($0) },
                                                       string = parts[2].replacingOccurrences(of: "\u{1B}", with: "")
                string.removingRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
                results.append(ANSIGroup(codes: codes.flatMap { Int($0) }, string: string))

            }
        }
        return results
    }

    func colorizeTheOutput(outputRawString: String) -> NSAttributedString {
        var myAttributedString = NSMutableAttributedString(string: "")

        var outputString = outputRawString.replacingOccurrences(of: "\u{1B}", with: "")

        outputString.removingRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
        myAttributedString = NSMutableAttributedString(string: outputString)
        myAttributedString.setAttributes([.foregroundColor: NSColor.white], range: NSRange(location: 0, length: outputString.count - 1))

        let parsedANSI = self.parseExistingANSI(string: outputRawString)
        parsedANSI.enumerated().forEach { argument in
            let (ansiIndex, ansi) = argument
            parsedANSI[ansiIndex].codes.forEach { code in
                guard !ansi.string.isEmpty, outputString.contains(ansi.string) else { return }

                let newColor = self.getCode(key: code)

                let ansiStart: Int = outputString.distance(from: outputString.startIndex, to: outputString.range(of: ansi.string)!.lowerBound)
                let ansiEnd: Int = outputString.distance(from: outputString.startIndex, to: outputString.range(of: ansi.string)!.upperBound)

                if code == 1 || code == 0 {
                    myAttributedString.addAttributes([.font: NSFont.boldSystemFont(ofSize: 12)], range: NSRange(location: ansiStart, length: ansiEnd - ansiStart))
                } else if let newColor = newColor {
                    myAttributedString.setAttributes([.foregroundColor: newColor], range: NSRange(location: ansiStart, length: ansiEnd - ansiStart))
                }
            }
        }
        return myAttributedString
    }
}
