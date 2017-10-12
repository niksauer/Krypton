//
//  Currency.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import SwiftKeccak

protocol Currency {
    var code: String { get }
}

struct CurrencyManager {
    
    static func getCurrency(from code: String) -> Currency? {
        if let fiatCurrency = Fiat(rawValue: code) {
            return fiatCurrency
        } else if let cryptoCurrency = Blockchain(rawValue: code) {
            return cryptoCurrency
        } else {
            return nil
        }
    }
    
    static func getAllCurrencies(for currency: Currency) -> [Currency]? {
        if Fiat(rawValue: currency.code) != nil {
            return Fiat.allValues
        } else if Blockchain(rawValue: currency.code) != nil {
            return Blockchain.allValues
        } else if Token.ERC20(rawValue: currency.code) != nil {
            return Token.ERC20.allValues
        } else {
            return nil
        }
    }
    
}

enum Blockchain: String, Currency {
    case ETH
    case XBT
    
    // MARK: - Private Properties
    /// dictionary mapping crypto currencies to their respective currency symbol
    private static let symbolForBlockchain: [Blockchain : String] = [
        .ETH : "Ξ",
        .XBT : "Ƀ"
    ]
    
    private static let nameForBlockchain: [Blockchain: String] = [
        .ETH: "Ethereum",
        .XBT: "Bitcoin"
    ]
    
    // MARK: - Public Properties
    /// returns currency symbol
    var symbol: String {
        return Blockchain.symbolForBlockchain[self]!
    }
    
    /// returns currency name
    var name: String {
        return Blockchain.nameForBlockchain[self]!
    }

    static var allValues = [XBT, ETH]
    
    // MARK: - Currency Protocol
    var code: String {
        return self.rawValue
    }
    
}

enum Fiat: String, Currency {
    case EUR
    case USD
    
    // MARK: - Public Properties
    static var allValues = [EUR, USD]
    
    // MARK: - Currency Protocol
    var code: String {
        return self.rawValue
    }
    
}

enum TradingPair: String {
    case ETHEUR
    case ETHUSD
    case XBTEUR
    case XBTUSD
    
    // https://api.kraken.com/0/public/AssetPairs
    static var allValues = [ETHEUR, ETHUSD, XBTEUR, XBTUSD]
    
    // MARK: - Public Type Methods
    /// returns trading pair constructed from specified crypto and fiat currency
    static func getTradingPair(a: Currency, b: Currency) -> TradingPair? {
        let tradingPair = a.code + b.code
        return TradingPair(rawValue: tradingPair)
    }
    
}
