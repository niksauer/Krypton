//
//  Crypto.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct Currency {
    
    // MARK: - Private Properties
    private static let symbolForCrypto: [Crypto : String ] = [
        .ETH : "Ξ",
        .BTC : "Ƀ"
    ]
    
    // MARK: - Public Properties
    enum Crypto: String {
        case ETH
        case BTC
    }
    
    enum Fiat: String {
        case EUR
        case USD
    }
    
    enum TradingPair: String {
        case ETHEUR
        case ETHUSD
    }
    
    
    
    // MARK: - Public Methods
    static func getSymbol(for cryptoCurrency: Crypto) -> String? {
        return symbolForCrypto[cryptoCurrency]
    }
    
    static func getTradingPair(cryptoCurrency: Crypto, fiatCurrency: Fiat) -> TradingPair? {
        let tradingPair = cryptoCurrency.rawValue + fiatCurrency.rawValue
        return TradingPair(rawValue: tradingPair)
    }
    
}
