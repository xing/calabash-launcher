import AppKit

fileprivate extension String {
    var itemIdentifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: self)
    }
}

extension NSUserInterfaceItemIdentifier {
    static let
    feedCell = "FeedCell".itemIdentifier,
    feedItemCell = "FeedItemCell".itemIdentifier,
    feedItemCell2 = "FeedItemCell2".itemIdentifier
}
