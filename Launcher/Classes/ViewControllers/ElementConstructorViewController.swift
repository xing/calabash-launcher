import AppKit
import CommandsCore

class ElementConstructorViewController: NSViewController, NSTableViewDataSource {

    var parentCollection: [String] = []
    var isParentView = false
    var elementIndex: Int!
    var parentElementIndex: Int!
    let fileManager = FileManager.default
    var retryCount: Int = 0
    
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var pushButton: NSButton!
    @IBOutlet weak var childCheckbox: NSButton!
    @IBOutlet weak var siblingCheckbox: NSButton!
    @IBOutlet weak var indexCheckbox: NSButton!

    @IBOutlet weak var outlineViewConstructor: NSOutlineView!

    @IBAction func pushButton(_ sender: Any) {
        getElements()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        pushButton.title = "Find unique elements for \(SharedElement.shared.stringValue ?? "Invalid string")"
    }

    @IBAction func doubleClickedItem(_ sender: NSOutlineView) {
        guard let item = sender.item(atRow: sender.clickedRow) as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(item, forType: .string)
        CommandsCore.CommandExecutor(launchPath: Constants.FilePaths.Bash.flash ?? "", arguments: [item]).execute()
    }
    
    func fileIsNotEmpty(filePath: String) -> Bool {
        if filePath.range(of: "txt") == nil {
            return true
        } else {
            var found = false
            if let aStreamReader = StreamReader(path: filePath) {
                defer {
                    aStreamReader.close()
                }
                if aStreamReader.nextLine() != nil {
                    found = true
                }
            }

            return found
        }
    }
    
    func waitingForFile(fileName: String, numberOfRetries: Int, completion: @escaping () -> Void) {
        self.spinner.startAnimation(self)
        guard FileManager.default.fileExists(atPath: fileName) && fileIsNotEmpty(filePath: fileName)
            else {
                if numberOfRetries == retryCount {
                    retryCount = 0
                    DispatchQueue.main.async {
                        self.spinner.stopAnimation(self)
                    }
                    return
                }
                DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 0.1,
                                                                                      execute: { [weak self] in
                                                                                        self?.waitingForFile(fileName: fileName, numberOfRetries: numberOfRetries, completion: completion)
                })

                retryCount += 1
                return
        }
        retryCount = 0

        completion()
    }
    
    func getElements() {
        parentCollection = []
        var elements = [String]()
        
        var arguments = SharedElement.shared.coordinates
        arguments.append(SharedElement.shared.stringValue ?? "")
        arguments.append(String(childCheckbox.state.rawValue))
        arguments.append(String(siblingCheckbox.state.rawValue))
        arguments.append(String(indexCheckbox.state.rawValue))
        
        let outputStream = CommandsCore.CommandTextOutputStream()
            outputStream.textHandler = {text in
            elements.append(text)
        }

        CommandsCore.CommandExecutor(launchPath: Constants.FilePaths.Bash.uniqueElements ?? "", arguments: arguments,  outputStream: outputStream).execute()       
        self.parentCollection.append(contentsOf: elements)
        self.outlineViewConstructor.reloadData()
        self.spinner.stopAnimation(self)
    }
}

extension ElementConstructorViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return parentCollection.count
     }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        parentElementIndex = index
        return parentCollection[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
}

extension ElementConstructorViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineViewConstructor.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedItemCell2"), owner: self) as? NSTableCellView
        if let textField = cell?.textField {
            textField.textColor = .black
            textField.stringValue = item as? String ?? ""
        }
        
        return cell
    }
}
