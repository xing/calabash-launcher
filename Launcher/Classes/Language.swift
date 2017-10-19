enum Language: String {
    case english = "English"
    case german = "German"
    case russian = "Russian"
    case italian = "Italian"
    case french = "French"
    case polish = "Polish"
    case other = "Other"
}

extension Language {
    var identifier: String {
        switch self {
        case .english:
            return "en"
        case .german:
            return "de"
        case .russian:
            return "ru"
        case .italian:
            return "it"
        case .french:
            return "fr"
        case .polish:
            return "pl"
        case .other:
            return "other"
        }
    }

    static var all: [Language] {
        return [.english, .german, .russian, .italian, .french, .polish, .other]
    }
}
