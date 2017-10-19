final class SharedElement {
    static let shared = SharedElement()

    private init() { }

    var stringValue: String?
    var coordinates: [String] = []
}
