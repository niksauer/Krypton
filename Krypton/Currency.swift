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
    var decimalDigits: Int { get }
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
        switch currency {
        case is Fiat:
            return Fiat.allValues
        case is Blockchain:
            return Blockchain.allValues
        case is Token.ERC20:
            return Token.ERC20.allValues
        default:
            return nil
        }
    }
    
}

enum Blockchain: String, Currency {
    case ETH
    case XBT
    
    // MARK: - Private Properties
    /// dictionary mapping crypto currencies to their respective currency symbol
    private static let symbolForBlockchain: [Blockchain: String] = [
        .ETH : "Ξ",
        .XBT : "Ƀ"
    ]
    
    private static let nameForBlockchain: [Blockchain: String] = [
        .ETH: "Ethereum",
        .XBT: "Bitcoin"
    ]
    
    private static let decimalDigitsForBlockchain: [Blockchain: Int] = [
        .ETH: 18,
        .XBT: 8
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

    static var allValues = [ETH]
    
    // MARK: - Currency Protocol
    var code: String {
        return self.rawValue
    }
    
    var decimalDigits: Int {
        return Blockchain.decimalDigitsForBlockchain[self]!
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
    
    var decimalDigits: Int {
        return 2
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
        let tradingPairRaw = a.code + b.code
        return TradingPair(rawValue: tradingPairRaw)
    }
    
}
