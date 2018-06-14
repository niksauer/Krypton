//
//  EtherscanTokenOperation.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct EtherscanTokenOperation: TokenOperationPrototype {
    let date: Date
    let identifier: String
    let type: TokenOperationType = .transfer
    let amount: Double
    let from: String
    let to: String
    let block: Int
}

extension EtherscanTokenOperation: Decodable {
    enum CodingKeys: String, CodingKey {
        case date = "timeStamp"
        case identifier = "hash"
        case type
        case amount = "value"
        case from
        case to
        case block = "blockNumber"
        case decimalDigits = "tokenDecimal"
    }
    
    init(from decoder: Decoder) throws {
        // container
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // date
        let unixTimestampString = try values.decode(String.self, forKey: .date)
        
        guard let unixTimestamp = Double(unixTimestampString) else {
            throw TokenError.invalidPrototype
        }
        
        date = Date(timeIntervalSince1970: unixTimestamp)
        
        // identifier
        identifier = try values.decode(String.self, forKey: .identifier)
        
        // amount
        let amountString = try values.decode(String.self, forKey: .amount)
        
        guard let rawAmount = Double(amountString) else {
            throw TokenError.invalidPrototype
        }
        
        let decimalDigitsString = try values.decode(String.self, forKey: .decimalDigits)
        
        guard let decimalDigits = Int(decimalDigitsString) else {
            throw TokenError.invalidPrototype
        }
        
        amount = rawAmount * (pow(10, -Double(decimalDigits)))
        
        // sender & receiver
        from = try values.decode(String.self, forKey: .from)
        to = try values.decode(String.self, forKey: .to)
        
        // block
        let blockString = try values.decode(String.self, forKey: .block)
        
        guard let block = Int(blockString) else {
            throw TokenError.invalidPrototype
        }
        
        self.block = block
    }
}
