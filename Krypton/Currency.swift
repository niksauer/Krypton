//
//  Currency.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct Currency {
    
    // MARK: - Public Properties
    enum Crypto: String {
        case ETH
        case BTC
        
        // MARK: - Private Properties
        /// dictionary mapping crypto currencies to their respective currency symbol
        private static let symbolForCrypto: [Crypto : String ] = [
            .ETH : "Ξ",
            .BTC : "Ƀ"
        ]
        
        // MARK: - Public Properties
        /// returns currency symbol
        var symbol: String {
            return Crypto.symbolForCrypto[self]!
        }
        
        static var allValues = [ETH, BTC]
    }

    enum Fiat: String {
        case EUR
        case USD
        
        static var allValues = [EUR, USD]
    }
    
    enum TradingPair: String {
        case ETHEUR
        case ETHUSD
        
        static var allValues = [ETHEUR, ETHUSD]
    }

    // MARK: - Public Methods
    /// returns trading pair constructed from specified crypto and fiat currency
    static func tradingPair(cryptoCurrency: Crypto, fiatCurrency: Fiat) -> TradingPair? {
        let tradingPair = cryptoCurrency.rawValue + fiatCurrency.rawValue
        return TradingPair(rawValue: tradingPair)
    }
    
}
