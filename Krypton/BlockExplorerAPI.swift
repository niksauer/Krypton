//
//  BlockExplorerAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 29.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum BlockExplorerError: Error {
    case invalidJSONData
}

struct BlockExplorerAPI {
    
    // MARK: - Private Properties
    private static let baseURL = "https://blockexplorer.com"
    
    private enum Method: String {
        case txlist
        case balance
    }
    
    // MARK: - Public Properties
    struct Transaction: TransactionPrototype {
        var identifier: String
        var date: Date
        var amount: Double
        var feeAmount: Double
        var block: Int
        var from: [String]
        var to: [String]
        var isError: Bool
        var isOutbound: Bool
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
    
    private static func transaction(fromJSON json: [String: Any], for address: String) -> Transaction? {
        guard let hash = json["txid"] as? String, let time = json["time"] as? Double, let block = json["blockheight"] as? Int, let vin = json["vin"] as? [[String: Any]], let vout = json["vout"] as? [[String: Any]], let feeAmount = json["fees"] as? Double else {
            return nil
        }
        
        var senders = [String]()
        var receivers = [String]()
        
        var isOutbound = false
        var amount = 0.0
        
        for input in vin {
            guard let sender = input["addr"] as? String, let inputAmount = input["value"] as? Double else {
                return nil
            }
            
            if sender.lowercased() == address.lowercased() {
                isOutbound = true
                amount = inputAmount
            }
            
            senders.append(sender)
        }
        
        for output in vout {
            guard let script = output["scriptPubKey"] as? [String: Any], let amountReceivers = script["addresses"] as? [String], let amountString = output["value"] as? String, let outputAmount = Double(amountString) else {
                return nil
            }
            
            if isOutbound {
                receivers.append(contentsOf: amountReceivers)
            } else {
                guard amountReceivers.contains(where: { $0.lowercased() == address.lowercased() }) else {
                    continue
                }
                
                receivers = [address]
                amount = amount + outputAmount
            }
        }
        
        return Transaction(identifier: hash, date: Date(timeIntervalSince1970: time), amount: amount, feeAmount: feeAmount, block: block, from: senders, to: receivers, isError: false, isOutbound: isOutbound)
    }
    
    // MARK: - Public Methods
    // MARK: Result Processing
    static func transactionHistory(fromJSON data: Data, for address: String) -> TransactionHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let transactionsArray = jsonDictionary["txs"] as? [[String: Any]] else {
                return .failure(BlockExplorerError.invalidJSONData)
            }
            
            var transactionHistory = [Transaction]()
    
            for transactionJSON in transactionsArray {
                if let transaction = transaction(fromJSON: transactionJSON, for: address) {
                    transactionHistory.append(transaction)
                }
            }
            
            return .success(transactionHistory)
        } catch {
            return .failure(error)
        }
    }
    
    static func balance(fromJSON data: Data) -> BalanceResult {
        guard let balanceString = String(data: data, encoding: .ascii), let balance = Double(balanceString) else {
            return .failure(BlockExplorerError.invalidJSONData)
        }
        
        return .success(balance)
    }
    
    // MARK: URL Builder
    static func transactionHistoryURL(for address: String) -> URL {
        return blockexplorerURL(method: .txlist, address: address)
    }
    
    static func balanceURL(for address: String) -> URL {
        return blockexplorerURL(method: .balance, address: address)
    }
    
}
