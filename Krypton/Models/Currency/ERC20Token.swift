//
//  ERC20Token.swift
//  Krypton
//
//  Created by Niklas Sauer on 10.11.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

protocol TokenFeatures: Currency {
    var address: String { get }
    var blockchain: Blockchain { get }
}

enum ERC20Token: String, TokenFeatures {

    case OMG
    case REP
    case STORJ
    
    // MARK: - Private Properties
    private static let nameForToken: [ERC20Token: String] = [
        .OMG: "OmiseGo",
        .REP: "Augur",
        .STORJ: "Storj"
    ]
    
    private static var addressForToken: [ERC20Token: String] = [
        .OMG: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07",
        .REP: "0xe94327d07fc17907b4db788e5adf2ed424addff6",
        .STORJ: "0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac"
    ]
    
    private static let decimalDigitsForToken: [ERC20Token: Int] = [
        .OMG: 18,
        .REP: 18,
        .STORJ: 8
    ]
    
    // MARK: - Public Properties
    static var allValues: [Currency] {
        return [OMG, REP, STORJ]
    }
    
    // MARK: - Initializers
    init?(address: String) {
        if let index = ERC20Token.addressForToken.values.index(of: address) {
            self.init(rawValue: ERC20Token.addressForToken.keys[index].rawValue)
        } else {
            return nil
        }
    }
    
    // MARK: - Currency
    var code: String {
        return self.rawValue
    }
    
    var name: String {
        return ERC20Token.nameForToken[self]!
    }
    
    var symbol: String {
        return code
    }
    
    var decimalDigits: Int {
        return ERC20Token.decimalDigitsForToken[self]!
    }
    
    var type: CurrencyType {
        return .Crypto
    }
    
    // MARK: - TokenFeatures
    var address: String {
        get {
            return ERC20Token.addressForToken[self]!
        }
        set {
            ERC20Token.addressForToken[self] = newValue
        }
    }
    
    var blockchain: Blockchain {
        return .Ethereum
    }
    
}
