//
//  Blockchain.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.11.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

enum Blockchain: String, Currency {
    
    case Ethereum
    case Bitcoin
    
    // MARK: - Public Type Properties
    static var allValues: [Currency] {
        return [Ethereum, Bitcoin]
    }
    
    // MARK: - Private Properties
    private static let codeForBlockchain: [Blockchain: String] = [
        .Ethereum: "ETH",
        .Bitcoin: "BTC"
    ]
    
    private static let symbolForBlockchain: [Blockchain: String] = [
        .Ethereum : "Ξ",
        .Bitcoin : "Ƀ"
    ]
    
    private static let decimalDigitsForBlockchain: [Blockchain: Int] = [
        .Ethereum: 18,
        .Bitcoin: 8
    ]
    
    // MARK: - Public Properties
    var associatedTokens: [TokenFeatures]? {
        switch self {
        case .Ethereum:
            return ERC20Token.allValues as? [TokenFeatures]
        default:
            return nil
        }
    }
    
    // MARK: - Currency
    var code: String {
        return Blockchain.codeForBlockchain[self]!
    }
    
    var name: String {
        return rawValue
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
        case .Ethereum:
            return ERC20Token.init(address: address)
        default:
            return nil
        }
    }
    
    func getToken(code: String) -> TokenFeatures? {
        switch self {
        case .Ethereum:
            return ERC20Token(rawValue: code)
        default:
            return nil
        }
    }

}
