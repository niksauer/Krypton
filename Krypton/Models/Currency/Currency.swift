//
//  Currency.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import SwiftKeccak

protocol Currency {
    var code: String { get }
    var name: String { get }
    var symbol: String { get }
    var decimalDigits: Int { get }
    var type: CurrencyType { get }
    
    func isEqual(to: Currency) -> Bool
}

extension Currency {
    func isEqual(to: Currency) -> Bool {
        return self.code == to.code
    }
}

enum CurrencyType: String {
    case Fiat
    case Crypto
}

struct CurrencyManager {
        
    // MARK: - Public Methods
    func getCurrency(from code: String) -> Currency? {
        return Fiat(rawValue: code) ?? Blockchain(rawValue: code) ?? ERC20Token(rawValue: code)
    }
    
    func getCurrencies(of type: CurrencyType) -> [Currency] {
        switch type {
        case .Fiat:
            return Fiat.allValues
        case .Crypto:
            return Blockchain.allValues as [Currency] + ERC20Token.allValues as [Currency]
        }
    }
    
}

struct CurrencyPair: Hashable {
    
    // MARK: - Public Properties
    let base: Currency
    let quote: Currency
    
    var name: String {
        return base.code + quote.code
    }
    
    
    // MARK: - Initialization
    init(base: Currency, quote: Currency) {
        self.base = base
        self.quote = quote
    }
        
    // MARK: - Hashable Protocol
    var hashValue: Int {
        return name.hashValue
    }
    
    static func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
        return lhs.base.isEqual(to: rhs.base) && lhs.quote.isEqual(to: rhs.quote)
    }
    
}
