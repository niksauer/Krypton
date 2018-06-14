//
//  EthplorerTokenOperation.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct EthplorerTokenOperation: TokenOperationPrototype {
    let date: Date
    let identifier: String
    let type: TokenOperationType
    let amount: Double
    let from: String
    let to: String
    let block: Int
}

extension EthplorerTokenOperation: Decodable {
    enum CodingKeys: String, CodingKey {
        case date = "timestamp"
        case identifier = "transactionHash"
        case type
        case amount = "value"
        case from
        case to
        
        // nested
        case tokenInfo
    }
    
    enum TokenInfoKeys: String, CodingKey {
        case decimalDigits = "decimals"
    }
    
    init(from decoder: Decoder) throws {
        // container
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let tokenInfo = try values.nestedContainer(keyedBy: TokenInfoKeys.self, forKey: .tokenInfo)
        
        // date
        let unixTimestamp = try values.decode(Double.self, forKey: .date)
        date = Date(timeIntervalSince1970: unixTimestamp)
        
        // identifier
        identifier = try values.decode(String.self, forKey: .identifier)
        
        // type
        let typeString = try values.decode(String.self, forKey: .type)
        
        guard let type = TokenOperationType(rawValue: typeString) else {
            throw TokenOperationError.invalidOperation
        }
        
        self.type = type
        
        // amount
        let decimalDigits: Int
        
        do {
            decimalDigits = try tokenInfo.decode(Int.self, forKey: .decimalDigits)
        } catch {
            let decimalsString = try tokenInfo.decode(String.self, forKey: .decimalDigits)
            
            guard let decimals = Int(decimalsString) else {
                throw error
            }
            
            decimalDigits = decimals
        }
        
        let rawAmount: Double
        
        do {
            rawAmount = try values.decode(Double.self, forKey: .amount)
        } catch {
            let amountString = try values.decode(String.self, forKey: .amount)
            
            guard let amount = Double(amountString) else {
                throw error
            }
            
            rawAmount = amount
        }
        
        amount = rawAmount * (pow(10, -Double(decimalDigits)))
        
        // sender & receiver & isOutbound
        from = try values.decode(String.self, forKey: .from)
        to = try values.decode(String.self, forKey: .to)
        
        // TODO: block
        block = 0
    }
}
