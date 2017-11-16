//
//  Blockchain.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.11.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum Blockchain: String, Currency {
    
    case ETH
    case BTC
    
    // MARK: - Private Properties
    private static let nameForBlockchain: [Blockchain: String] = [
        .ETH: "Ethereum",
        .BTC: "Bitcoin"
    ]
    
    private static let symbolForBlockchain: [Blockchain: String] = [
        .ETH : "Ξ",
        .BTC : "Ƀ"
    ]
    
    private static let decimalDigitsForBlockchain: [Blockchain: Int] = [
        .ETH: 18,
        .BTC: 8
    ]
    
    // MARK: - Public Properties
    static var allValues: [Currency] {
        return [ETH, BTC]
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
    
    // MARK: - Public Methods
    func getToken(address: String) -> TokenFeatures? {
        switch self {
        case .ETH:
            return ERC20Token.init(address: address)
        default:
            return nil
        }
    }
    
    func getToken(code: String) -> TokenFeatures? {
        switch self {
        case .ETH:
            return ERC20Token(rawValue: code)
        default:
            return nil
        }
    }
    
}
