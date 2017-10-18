//
//  RegexHandler.swift
//  Calabash Launcher
//
//  Created by new mac on 17.10.17.
//  Copyright © 2017 XING. All rights reserved.
//

import Foundation

class RegexHandler {
    func matches(for regex: String, in text: String, global: Bool = false) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: regex) else { return [] }
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
        
        if !global && results.count == 1 {
            var result: [String] = []
            for i in 0..<results[0].numberOfRanges {
                result.append(nsString.substring(with: results[0].range(at: i)))
            }
            return result
        }
        else {
            return results.map { nsString.substring(with: $0.range) }
        }
    }
}
