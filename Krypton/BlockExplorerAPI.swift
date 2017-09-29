//
//  BlockchainAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 29.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum BlockexplorerError: Error {
    case invalidJSONData
}

struct BlockexplorerAPI {
    
    // MARK: - Private Properties
    private static let baseURL = "https://blockexplorer.com"
    
    private enum Method: String {
        case txlist
        case balance
    }
    
    // MARK: - Private Methods
    private static func blockexplorerURL(method: Method, address: String) -> URL {
        var components = URLComponents(string: baseURL)!
        
        switch method {
        case .balance:
            components.path = "/api/addr/\(address)/balance"
        case .txlist:
            components.path = "/api/txs/"
            components.queryItems = [URLQueryItem(name: "address", value: address)]
        }
        
        return components.url!
    }
    
    private static func transaction(fromJSON json: [String: Any], for address: Address) -> [TransactionProto]? {
        guard let hash = json["txid"] as? String, let time = json["time"] as? Double, let block = json["blockheight"] as? Int32, let vin = json["vin"] as? [[String: Any]], let firstSender = vin.first?["addr"] as? String, let vout = json["vout"] as? [[String: Any]] else {
            return nil
        }
        
        var transactions = [TransactionProto]()
        
        for out in vout {
            guard let script = out["scriptPubKey"] as? [String: Any], let addresses = script["addresses"] as? [String], let firstReceiver = addresses.first, let amountString = out["value"] as? String, let amount = Double(amountString) else {
                continue
            }
            
//            guard firstSender == address.address! || firstReceiver == address.address! else {
//                continue
//            }
            
            let transaction = TransactionProto(identifier: hash, date: NSDate(timeIntervalSince1970: time), amount: amount, from: firstSender, to: firstReceiver, type: .normal, block: block)
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    // MARK: - Public Methods
    static func transactionHistory(fromJSON data: Data, for address: Address) -> TransactionHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let transactionsArray = jsonDictionary["txs"] as? [[String: Any]] else {
                return .failure(BlockexplorerError.invalidJSONData)
            }
            
            var transactionHistory = [TransactionProto]()
    
            for transactionJSON in transactionsArray {
                if let transactions = transaction(fromJSON: transactionJSON, for: address) {
                    transactionHistory.append(contentsOf: transactions)
                }
            }
            
            return .success(transactionHistory)
        } catch {
            return .failure(error)
        }
    }
    
    static func balance(fromJSON data: Data) -> BalanceResult {
        guard let balanceString = String(data: data, encoding: .ascii), let balance = Double(balanceString) else {
            return .failure(BlockexplorerError.invalidJSONData)
        }
        
        return .success(balance)
    }
    
    // MARK: - Private Methods
    static func transactionHistoryURL(for address: String) -> URL {
        return blockexplorerURL(method: .txlist, address: address)
    }
    
    static func balanceURL(for address: String) -> URL {
        return blockexplorerURL(method: .balance, address: address)
    }
    
}
