import Cocoa
import Foundation
import AppKit

class ElementConstructor: NSViewController, NSTableViewDataSource {
    
    var parent_collection_cut_list: [String] = []
    var parent_collection_list: [String] = []
    var isParentView = false
    var elementIndex: Int!
    var parentElementIndex: Int!
    let fileManager = FileManager.default
    var runDeviceTask7: Process!
    var buildTaskNew122: Process!
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
        pushButton.title = "Find unique elements for \(Shared.shared.stringValue ?? "Invalid string")"
    }

    @IBAction func doubleClickedItem(_ sender: NSOutlineView) {
        guard let item = sender.item(atRow: sender.clickedRow) as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(item, forType: .string)
        flashElement(element: item)
    }    
    
    func fileIsNotEmpty(filePath: String)->Bool {
        
        if filePath.range(of: "txt") == nil {
            return true
        } else {
            var found:Bool = false
            if let aStreamReader = StreamReader(path: filePath) {
                defer {
                    aStreamReader.close()
                }
                if aStreamReader.nextLine() != nil {
                    found = true
                }
            }
            if found {
                return true
            } else {
                return false
            }
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
        parent_collection_list = []
        do {
            try fileManager.removeItem(atPath: "/tmp/uniq_elements.txt")
        } catch _ as NSError {}
        var arguments:[String] = Shared.shared.coordinates
        arguments.append(Shared.shared.stringValue)
        arguments.append(String(childCheckbox.state.rawValue))
        arguments.append(String(siblingCheckbox.state.rawValue))
        arguments.append(String(indexCheckbox.state.rawValue))
        
        getElementsByOffset(arguments)
        
        let filePath = "/tmp/uniq_elements.txt"
        
        waitingForFile(fileName: "/tmp/uniq_elements.txt", numberOfRetries: 999) {
        DispatchQueue.main.async {
        if let aStreamReader = StreamReader(path: filePath) {
            defer {
                aStreamReader.close()
            }
            while let url_line = aStreamReader.nextLine() {

                    self.parent_collection_list.append(url_line)
                }
            }
            
            if self.parent_collection_list == [] {
                sleep(1)
                if let aStreamReader = StreamReader(path: filePath) {
                    defer {
                        aStreamReader.close()
                    }
                    while let url_line = aStreamReader.nextLine() {
                       
                        self.parent_collection_list.append(url_line)
                        }
                    }
                }
        
    
        
        self.outlineViewConstructor.reloadData()
        self.spinner.stopAnimation(self)
        }
    }
    }
    
    
    func getElementsByOffset(_ arguments:[String]) {
        
        let taskQueue6 = DispatchQueue.global(qos: .background)
        
        taskQueue6.async {
            
            let path = Constants.FilePaths.Bash.uniqueElements
            self.runDeviceTask7 = Process()
            self.runDeviceTask7.launchPath = path
            
            self.runDeviceTask7.arguments = arguments
            
            self.runDeviceTask7.terminationHandler = {
                task in
                
                DispatchQueue.main.async(execute: {
                }) 
            }
            
            self.runDeviceTask7.launch()
            self.runDeviceTask7.waitUntilExit()
            
            
            DispatchQueue.main.async(execute: {
            })
        }
    }
    
    func flashElement(element : String) {
        let taskQueueNew = DispatchQueue.global(qos: .background)
        
        taskQueueNew.async {
            let path = Constants.FilePaths.Bash.flash
            self.buildTaskNew122 = Process()
            self.buildTaskNew122.launchPath = path
            var arguments:[String] = []
            arguments.append(element)
            self.buildTaskNew122.arguments = arguments
            self.buildTaskNew122.launch()
        }
    }
}

extension ElementConstructor: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return parent_collection_list.count
     }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            parentElementIndex = index
            return parent_collection_list[index]
        }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            return false
    }
    
}

extension ElementConstructor: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineViewConstructor.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedItemCell2"), owner: self) as? NSTableCellView
        if let textField = cell?.textField {
            textField.textColor = .black
            textField.stringValue = item as? String ?? ""
        }
        
        return cell
    }
}
