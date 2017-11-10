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
    var type: CurrencyType { get }
}

enum CurrencyType {
    case fiat
    case crypto
}

struct CurrencyManager {
    
    static func getCurrency(from code: String) -> Currency? {
        return Fiat(rawValue: code) ?? Blockchain(rawValue: code) ?? Token.ERC20(rawValue: code)
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
    
    static func getAllValues(for currencyType: CurrencyType) -> [Currency] {
        switch currencyType {
        case .fiat:
            return Fiat.allValues
        case .crypto:
            return Blockchain.allValues as [Currency] + Token.ERC20.allValues as [Currency]
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

    static var allValues = [ETH, XBT]
    
    // MARK: - Currency Protocol
    var code: String {
        return self.rawValue
    }
    
    var decimalDigits: Int {
        return Blockchain.decimalDigitsForBlockchain[self]!
    }
    
    var type: CurrencyType {
        return .crypto
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
    
    var type: CurrencyType {
        return .fiat
    }
    
}

struct TradingPair: Hashable {
    
    // MARK: - Public Properties
    let base: Currency
    let quote: Currency
    private(set) public var intermediate: Currency?
    
    var name: String {
        return base.code + quote.code
    }
    
    var currentPrice: Double? {
        return getValue(on: Date())
    }
    
    // MARK: - Initialization
    init(base: Currency, quote: Currency) {
        self.base = base
        self.quote = quote
    }
    
    init(base: Currency, quote: Currency, intermediate: Currency) {
        self.base = base
        self.quote = quote
        self.intermediate = intermediate
    }
    
    // MARK: - Public Methods
    func registerForUpdates() {
        if let intermediate = intermediate {
            TickerDaemon.addTradingPair(TradingPair(base: base, quote: intermediate))
            TickerDaemon.addTradingPair(TradingPair(base: intermediate, quote: quote))
        } else {
            TickerDaemon.addTradingPair(self)
        }
    }
    
    func getValue(on date: Date) -> Double? {
        if let intermediate = intermediate {
            let baseInterPair = TradingPair(base: base, quote: intermediate)
            let interQuotePair = TradingPair(base: intermediate, quote: quote)
        
            let baseInterValue: Double?
            let interQuoteValue: Double?
            
            switch date {
            case _ where date.isToday:
                baseInterValue = TickerDaemon.getCurrentPrice(for: baseInterPair)
                interQuoteValue = TickerDaemon.getCurrentPrice(for: interQuotePair)
            default:
                baseInterValue = TickerPrice.getTickerPrice(for: baseInterPair, on: date)?.value
                interQuoteValue = TickerPrice.getTickerPrice(for: interQuotePair, on: date)?.value
            }
            
            guard baseInterValue != nil, interQuoteValue != nil else {
                return nil
            }
            
            return baseInterValue! * interQuoteValue!
        } else {
            if date.isToday {
                return TickerDaemon.getCurrentPrice(for: self)
            } else {
                return TickerPrice.getTickerPrice(for: self, on: date)?.value
            }
        }
    }
    
    // MARK: - Hashable Protocol
    var hashValue: Int {
        return name.hashValue
    }
    
    static func ==(lhs: TradingPair, rhs: TradingPair) -> Bool {
        return lhs.base.code == rhs.base.code && lhs.quote.code == rhs.quote.code
    }
    
}
