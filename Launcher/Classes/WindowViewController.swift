import Cocoa
import Foundation
import AppKit

class WindowViewControler: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = .lightGray
    }
}
