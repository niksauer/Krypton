//
//  Currency.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import SwiftKeccak

protocol CurrencyFeatures {
    var code: String { get }
    var name: String { get }
    var symbol: String { get }
    var decimalDigits: Int { get }
    var type: CurrencyType { get }
}

enum CurrencyType: String {
    case Fiat
    case Crypto
}

struct CurrencyManager {
    
    // MARK: - Private Properties
    private static let allCurrencies = [Blockchain.self, Fiat.self, Token.self] as [Any]
    
    // MARK: - Public Methods
    static func getCurrency(from code: String) -> CurrencyFeatures? {
        return Fiat(rawValue: code) ?? Blockchain(rawValue: code) ?? ERC20Token(rawValue: code)
    }
    
    static func getCurrencies(of type: CurrencyType) -> [CurrencyFeatures] {
        switch type {
        case .Fiat:
            return Fiat.allValues
        case .Crypto:
            return Blockchain.allValues as [CurrencyFeatures] + ERC20Token.allValues as [CurrencyFeatures]
        }
    }
    
}

enum Blockchain: String, CurrencyFeatures {
    
    case ETH
    case XBT
    
    // MARK: - Private Properties
    private static let nameForBlockchain: [Blockchain: String] = [
        .ETH: "Ethereum",
        .XBT: "Bitcoin"
    ]
    
    private static let symbolForBlockchain: [Blockchain: String] = [
        .ETH : "Ξ",
        .XBT : "Ƀ"
    ]

    private static let decimalDigitsForBlockchain: [Blockchain: Int] = [
        .ETH: 18,
        .XBT: 8
    ]

    // MARK: - Public Properties
    static var allValues: [CurrencyFeatures] {
        return [ETH, XBT]
    }
    
    // MARK: - Currency Protocol
    var code: String {
        return self.rawValue
    }
    
    var name: String {
        return Blockchain.nameForBlockchain[self]!
    }
    
    var symbol: String {
        return Blockchain.symbolForBlockchain[self]!
    }
    
    var decimalDigits: Int {
        return Blockchain.decimalDigitsForBlockchain[self]!
    }
    
    var type: CurrencyType {
        return .Crypto
    }
    
    // MARK: - Currency Protocol
    func getToken(address: String) -> TokenFeatures? {
        switch self {
        case .ETH:
            return ERC20Token.init(address: address)
        default:
            return nil
        }
    }

}

enum Fiat: String, CurrencyFeatures {
    
    case EUR
    case USD
    
    // MARK: - Private Properties
    private static let nameForFiat: [Fiat: String] = [
        .EUR: "Euro",
        .USD: "Dollar"
    ]
    
    private static let symbolForFiat: [Fiat: String] = [
        .EUR : "€",
        .USD : "$"
    ]
    
    // MARK: - Currency Protocol
    static var allValues: [CurrencyFeatures] {
        return [EUR, USD]
    }
    
    var code: String {
        return self.rawValue
    }
    
    var name: String {
        return Fiat.nameForFiat[self]!
    }
    
    var symbol: String {
        return Fiat.symbolForFiat[self]!
    }
    
    var decimalDigits: Int {
        return 2
    }
    
    var type: CurrencyType {
        return .Fiat
    }

}

struct CurrencyPair: Hashable {

    // MARK: - Private Properties
    private var intermediate: CurrencyFeatures?
    
    // MARK: - Public Properties
    let base: CurrencyFeatures
    let quote: CurrencyFeatures
    
    var name: String {
        return base.code + quote.code
    }
    
    var currentRate: Double? {
        return getRate(on: Date())
    }
    
    // MARK: - Initialization
    init(base: CurrencyFeatures, quote: CurrencyFeatures) {
        if let token = base as? TokenFeatures, quote.type != .Crypto {
            self.base = base
            self.quote = quote
            self.intermediate = token.blockchain
        } else {
            self.base = base
            self.quote = quote
        }
    }
    
    // MARK: - Public Methods
    func getRate(on date: Date) -> Double? {
        if let intermediate = intermediate {
            let baseInterPair = CurrencyPair(base: base, quote: intermediate)
            let interQuotePair = CurrencyPair(base: intermediate, quote: quote)
        
            let baseInterValue: Double?
            let interQuoteValue: Double?
            
            switch date {
            case _ where date.isToday:
                baseInterValue = TickerDaemon.getCurrentPrice(for: baseInterPair)
                interQuoteValue = TickerDaemon.getCurrentPrice(for: interQuotePair)
            default:
                baseInterValue = MarketPrice.getMarketPrice(for: baseInterPair, on: date)
                interQuoteValue = MarketPrice.getMarketPrice(for: interQuotePair, on: date)
            }
            
            guard baseInterValue != nil, interQuoteValue != nil else {
                return nil
            }
            
            return baseInterValue! * interQuoteValue!
        } else {
            if date.isToday {
                return TickerDaemon.getCurrentPrice(for: self)
            } else {
                return MarketPrice.getMarketPrice(for: self, on: date)
            }
        }
    }
    
    func registerForUpdates() {
        if let intermediate = intermediate {
            TickerDaemon.addCurrencyPair(CurrencyPair(base: base, quote: intermediate))
            TickerDaemon.addCurrencyPair(CurrencyPair(base: intermediate, quote: quote))
        } else {
            TickerDaemon.addCurrencyPair(self)
        }
    }
    
    // MARK: - Hashable Protocol
    var hashValue: Int {
        return name.hashValue
    }
    
    static func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
        return lhs.base.code == rhs.base.code && lhs.quote.code == rhs.quote.code
    }
    
}
