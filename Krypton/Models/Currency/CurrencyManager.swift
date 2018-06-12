//
//  CurrencyManager.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import SwiftKeccak

enum CurrencyType: String {
    case Fiat
    case Crypto
}

struct CurrencyManager {
        
    // MARK: - Public Methods
    func getCurrency(from code: String) -> Currency? {
        return Fiat(rawValue: code) ?? Blockchain(rawValue: code) ?? ERC20Token(rawValue: code)
    }
    
    func getCurrencies(type: CurrencyType) -> [Currency] {
        switch type {
        case .Fiat:
            return Fiat.allValues
        case .Crypto:
            return Blockchain.allValues as [Currency] + ERC20Token.allValues as [Currency]
        }
    }
    
}
