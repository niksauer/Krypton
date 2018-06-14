//
//  EthplorerToken.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct EthplorerToken: TokenProtoype {
    let balance: Double
    let address: String
    let name: String
    let symbol: String
    let decimalDigits: Int
}

extension EthplorerToken: Decodable {
    enum CodingKeys: String, CodingKey {
        case balance
        
        // nested
        case tokenInfo
    }
    
    enum TokenInfoKeys: String, CodingKey {
        case address
        case name
        case symbol
        case decimalDigits = "decimals"
    }
    
    init(from decoder: Decoder) throws {
        // container
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let tokenInfo = try values.nestedContainer(keyedBy: TokenInfoKeys.self, forKey: .tokenInfo)
        
        // general
        address = try tokenInfo.decode(String.self, forKey: .address)
        name = try tokenInfo.decode(String.self, forKey: .name)
        symbol = try tokenInfo.decode(String.self, forKey: .symbol)
        
        // balance & decimal digits
        let rawBalance = try values.decode(Double.self, forKey: .balance)
        
        do {
            decimalDigits = try tokenInfo.decode(Int.self, forKey: .decimalDigits)
        } catch {
            let decimalsString = try tokenInfo.decode(String.self, forKey: .decimalDigits)
            
            guard let decimals = Int(decimalsString) else {
                throw error
            }
            
            self.decimalDigits = decimals
        }
        
        balance = rawBalance * (pow(10, -Double(decimalDigits)))
    }
}
