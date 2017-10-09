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
    var name: String { get }
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
    var blockchain: String {
        return Blockchain.nameForBlockchain[self]!
    }

    static var allValues = [ETH, XBT]
    
    // MARK: - Currency Protocol
    var name: String {
        return self.rawValue
    }
    
}

//enum ERC20Token: String, Currency {
//    case OMG
//    case REP
//    case STORJ
//
//    private static let nameForToken: [ERC20Token: String] = [
//        .OMG: "OmiseGo",
//        .REP: "Augur",
//        .STORJ: "Storj"
//    ]
//
//    // MARK: - Currency Protocol
//    var name: String {
//        return self.rawValue
//    }
//}

enum Fiat: String, Currency {
    case EUR
    case USD
    
    // MARK: - Public Properties
    static var allValues = [EUR, USD]
    
    // MARK: - Currency Protocol
    var name: String {
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
    static func getTradingPair<A: Currency, B: Currency>(a: A, b: B) -> TradingPair? {
        let tradingPair = a.name + b.name
        return TradingPair(rawValue: tradingPair)
    }
}
