//
//  Language.swift
//  Calabash Launcher
//
//  Created by Bas Thomas Broek on 12/10/2017.
//  Copyright © 2017 XING. All rights reserved.
//

import Foundation

enum Language: String {
    case english = "English"
    case german = "German"
}

extension Language {
    var identifier: String {
        switch self {
        case .english:
            return "en"
        case .german:
            return "de"
        }
    }
}
