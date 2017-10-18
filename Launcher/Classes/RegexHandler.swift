//
//  RegexHandler.swift
//  Calabash Launcher
//
//  Created by new mac on 17.10.17.
//  Copyright © 2017 XING. All rights reserved.
//

import Foundation

class RegexHandler {
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        do {
            
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            
            let results = regex.matches(in: text,
                                        options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}
            
        } catch let error as NSError {
            
            print("invalid regex: \(error.localizedDescription)")
            
            return []
        }}
}
