//
//  Filter.swift
//  Krypton
//
//  Created by Niklas Sauer on 09.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct Filter {
    
    // MARK: - Private Properties
    private var displayNameForOption: [String : String] = [
        "transactionType" : "Type",
        "hasUserExchangeValue" : "Manual Value",
        "isUnread" : "Unread",
        "isError" : "Error"
    ]
    
    // MARK: - Public Properties
    var transactionType: TransactionType = .all
    var isUnread: Bool = true
    var isError: Bool = false
    var hasUserExchangeValue: Bool = false
    
    var isApplied: Bool {
        return transactionType != .all || isUnread || isError || hasUserExchangeValue
    }
    
    var description: String {
        var activeProperties: [String] = []
        
        for option in allProperties() {
            if let isActive = option.value as? Bool, isActive {
                activeProperties.append(displayNameForOption[option.key]!)
            }
            
            if let type = option.value as? TransactionType, type != .all {
                activeProperties.append(displayNameForOption[option.key]!)
            }
        }
        
        return activeProperties.joined(separator: ", ")
    }
    
    // MARK: - Private Methods
    private func allProperties() -> [String: Any] {
        var result: [String: Any] = [:]
        
        let mirror = Mirror(reflecting: self)
        
        for (labelMaybe, valueMaybe) in mirror.children {
            guard let label = labelMaybe else {
                continue
            }
            
            result[label] = valueMaybe
        }
        
        return result
    }
    
}
