//
//  Currency.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CryptoSwift
import SwiftKeccak

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
        
        // MARK: - Public Methods
        static func isAddress(_ addressString: String, cryptoCurrency: Crypto) -> Bool {
            switch cryptoCurrency {
            case .ETH:
                let allLowerCapsTest = NSPredicate(format: "SELF MATCHES %@", "(0x)?[0-9a-f]{40}")
                let allUpperCapsTest = NSPredicate(format: "SELF MATCHES %@", "(0x)?[0-9A-F]{40}")
                
                if !allLowerCapsTest.evaluate(with: addressString.lowercased()) {
                    // basic requirements
                    return false
                } else if allLowerCapsTest.evaluate(with: addressString) || allUpperCapsTest.evaluate(with: addressString) {
                    // either all lower or upper case
                    return true
                } else {
                    return isChecksumAddress(addressString)
                }
            case .XBT:
                return false
            }
        }
        
        static func isChecksumAddress(_ addressString: String) -> Bool{
            let address = addressString.replacingOccurrences(of: "0x", with: "")
            let addressHash = keccak256(address.lowercased()).hexEncodedString()
            
            for (index, character) in address.enumerated() {
                guard let hashDigit = Int(String(addressHash[index]), radix: 16) else {
                    return false
                }
                
                let digit = String(character)
                let uppercaseDigit = String(digit).uppercased()
                let lowercaseDigit = String(digit).lowercased()
                
                if hashDigit > 7 && uppercaseDigit != digit || hashDigit <= 7 && lowercaseDigit != digit {
                    return false
                }
            }
            
            return true
        }
        
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
