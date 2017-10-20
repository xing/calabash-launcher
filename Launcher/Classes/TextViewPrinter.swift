import Foundation
import AppKit

class TextViewPrinter {
    
    let textView: NSTextView
    
    init(textView: NSTextView) {
        self.textView = textView
    }
    
    func printToTextView(_ outputString : String) {
        if !outputString.isEmpty {
            textView.textStorage?.append(BashOutput.colorized(string: outputString))
        }
        let range = NSRange(location: textView.string.count, length: 0)
        textView.scrollRangeToVisible(range)
    }
}
