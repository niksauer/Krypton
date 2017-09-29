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
        case XBT
        
        // MARK: - Private Properties
        /// dictionary mapping crypto currencies to their respective currency symbol
        private static let symbolForCrypto: [Crypto : String] = [
            .ETH : "Ξ",
            .XBT : "Ƀ"
        ]
        
        private static let blockchainForCrypto: [Crypto: String] = [
            .ETH: "Ethereum",
            .XBT: "Bitcoin"
        ]
        
        // MARK: - Public Properties
        /// returns currency symbol
        var symbol: String {
            return Crypto.symbolForCrypto[self]!
        }
        
        /// returns currency name
        var blockchain: String {
            return Crypto.blockchainForCrypto[self]!
        }
        
        static var allValues = [ETH, XBT]
    }

    enum Fiat: String {
        case EUR
        case USD
        
        static var allValues = [EUR, USD]
    }
    
    enum TradingPair: String {
        case ETHEUR
        case ETHUSD
        case XBTEUR
        case XBTUSD
        
//        https://api.kraken.com/0/public/AssetPairs
        static var allValues = [ETHEUR, ETHUSD, XBTEUR, XBTUSD]
        
        // MARK: - Public Class Methods
        /// returns trading pair constructed from specified crypto and fiat currency
        static func getTradingPair(cryptoCurrency: Crypto, fiatCurrency: Fiat) -> TradingPair? {
            let tradingPair = cryptoCurrency.rawValue + fiatCurrency.rawValue
            return TradingPair(rawValue: tradingPair)
        }
    }
    
}
