import AppKit

enum BashOutput {

    private static let colorCodes: [Int: NSColor] = [
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

    private static let styleCodes: [Int: NSFont] = [
        0: .systemFont(ofSize: 15),
        1: .boldSystemFont(ofSize: 15),
    ]

    private static func code(forKey key: Int) -> Any? {
        if let colorCode = colorCodes[key] {
            return colorCode
        } else if let styleCode = styleCodes[key] {
            return styleCode
        }
        return nil
    }

    struct ANSIGroup {
        let codes: [Int]
        let string: String
    }

    private static func parseExistingANSI(string: String) -> [ANSIGroup] {
        var results: [ANSIGroup] = []
        let regexHandler = RegexHandler()
        let matches = regexHandler.matches(for: "\\u001B\\[([^m]*)m(.+?)\\u001B\\[0m", in: string, global: true)

        for match in matches {
            let mutlipleMatches = regexHandler.matches(for: "\\u001B\\[([^m]*)m", in: match, global: true)
            if mutlipleMatches.count > 2 {
                for i in 0...mutlipleMatches.count - 2 {
                    let strippedMatches = mutlipleMatches[i]
                        .replacingOccurrences(of: "\u{1B}[", with: "")
                        .replacingOccurrences(of: "m", with: "")
                    let regex = "\\u001B\\[(\(strippedMatches))m(.+?)\\u001B\\[0m"
                    let multipleParts = regexHandler.matches(for: regex, in: match)

                    if multipleParts.count < 2 {
                        continue
                    }

                    let codes = multipleParts[1]
                        .split { $0 == ";" }
                        .map(String.init)
                        .flatMap(Int.init)
                    let string = multipleParts[2]
                        .replacingOccurrences(of: "\u{1B}", with: "")
                        .filteredRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
                    results.append(ANSIGroup(codes: codes, string: string))
                }
            } else {
                let parts = regexHandler.matches(for: "\\u001B\\[([^m]*)m(.+?)\\u001B\\[0m", in: match)
                let codes = parts[1]
                    .split { $0 == ";" }
                    .map(String.init)
                    .flatMap(Int.init)
                let string = parts[2]
                    .replacingOccurrences(of: "\u{1B}", with: "")
                    .filteredRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
                results.append(ANSIGroup(codes: codes, string: string))
            }
        }
        return results
    }

    static func colorize(string: String, in textView: NSTextView) {
        var myAttributedString = NSMutableAttributedString(string: "")

        let outputString = string
            .replacingOccurrences(of: "\u{1B}", with: "")
            .filteredRegexMatches(pattern: "\\[(?<=\\[)(\\d)(.*?)(?=\\m)\\m")
        myAttributedString = NSMutableAttributedString(string: outputString)
        myAttributedString.setAttributes([.foregroundColor: NSColor.white], range: NSRange(location: 0, length: outputString.count - 1))

        let parsedANSI = self.parseExistingANSI(string: string)
        parsedANSI.enumerated().forEach { argument in
            let (ansiIndex, ansi) = argument
            parsedANSI[ansiIndex].codes.forEach { code in
                guard !ansi.string.isEmpty, outputString.contains(ansi.string) else { return }

                let newColor = self.code(forKey: code)

                let ansiStart: Int = outputString.distance(from: outputString.startIndex, to: outputString.range(of: ansi.string)!.lowerBound)
                let ansiEnd: Int = outputString.distance(from: outputString.startIndex, to: outputString.range(of: ansi.string)!.upperBound)

                if code == 1 || code == 0 {
                    myAttributedString.addAttributes([.font: NSFont.boldSystemFont(ofSize: 12)], range: NSRange(location: ansiStart, length: ansiEnd - ansiStart))
                } else if let newColor = newColor {
                    myAttributedString.setAttributes([.foregroundColor: newColor], range: NSRange(location: ansiStart, length: ansiEnd - ansiStart))
                }
            }
        }
        textView.textStorage?.append(myAttributedString)
    }
}
