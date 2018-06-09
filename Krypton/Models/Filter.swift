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
    private static var displayNameForOption: [String : String] = [
        "transactionType" : "Type",
        "hasUserExchangeValue" : "Manual Value",
        "isUnread" : "Unread",
        "isError" : "Error"
    ]
    
    // MARK: - Public Properties
    var transactionType: TransactionType
    var isUnread: Bool
    var isError: Bool
    var hasUserExchangeValue: Bool
    
    var isApplied: Bool {
        return transactionType != .all || isUnread || isError || hasUserExchangeValue
    }
    
    var description: String {
        var activeProperties: [String] = []
        
        for option in allProperties() {
            if let isActive = option.value as? Bool, isActive {
                activeProperties.append(Filter.displayNameForOption[option.key]!)
            }
            
            if let type = option.value as? TransactionType, type != .all {
                activeProperties.append(Filter.displayNameForOption[option.key]!)
            }
        }
        
        return activeProperties.joined(separator: ", ")
    }
    
    // MARK: - Initialization
    init() {
        self.transactionType = .all
        self.isUnread = true
        self.isError = false
        self.hasUserExchangeValue = false
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
