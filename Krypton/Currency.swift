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
    static func getCurrency(from code: String) -> Currency? {
        return Fiat(rawValue: code) ?? Blockchain(rawValue: code) ?? ERC20Token(rawValue: code)
    }
    
    static func getCurrencies(of type: CurrencyType) -> [Currency] {
        switch type {
        case .Fiat:
            return Fiat.allValues
        case .Crypto:
            return Blockchain.allValues as [Currency] + ERC20Token.allValues as [Currency]
        }
    }
    
}

struct CurrencyPair: Hashable {

    // MARK: - Private Properties
    private var intermediate: Currency?
    
    // MARK: - Public Properties
    let base: Currency
    let quote: Currency
    
    var name: String {
        return base.code + quote.code
    }
    
    var currentRate: Double? {
        return getRate(on: Date())
    }
    
    // MARK: - Initialization
    init(base: Currency, quote: Currency) {
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
    
    func register() {
        if let intermediate = intermediate {
            TickerDaemon.addCurrencyPair(CurrencyPair(base: base, quote: intermediate))
            TickerDaemon.addCurrencyPair(CurrencyPair(base: intermediate, quote: quote))
        } else {
            TickerDaemon.addCurrencyPair(self)
        }
    }
    
    func deregister() {
        if let intermediate = intermediate {
            TickerDaemon.removeCurrencyPair(CurrencyPair(base: base, quote: intermediate))
            TickerDaemon.removeCurrencyPair(CurrencyPair(base: intermediate, quote: quote))
        } else {
            TickerDaemon.removeCurrencyPair(self)
        }
    }
    
    // MARK: - Hashable Protocol
    var hashValue: Int {
        return name.hashValue
    }
    
    static func ==(lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
        return lhs.base.isEqual(to: rhs.base) && lhs.quote.isEqual(to: rhs.quote)
    }
    
}
