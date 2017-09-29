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
    
    private static func transaction(fromJSON json: [String: Any]) -> TransactionProto? {
        return nil
    }
    
    private static func bitcoin(from satoshiString: String) -> Double? {
        return nil
    }
    
    // MARK: - Public Methods
    static func transactionHistory(fromJSON data: Data) -> TransactionHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let transactionsArray = jsonDictionary["txs"] as? [[String: Any]] else {
                return .failure(BlockexplorerError.invalidJSONData)
            }
            
            var transactionHistory = [TransactionProto]()
            
            for transactionJSON in transactionsArray {
                if let transaction = transaction(fromJSON: transactionJSON) {
                    transactionHistory.append(transaction)
                }
            }
            
            return .success(transactionHistory)
        } catch {
            return .failure(error)
        }
    }
    
    static func balance(fromJSON data: Data) -> BalanceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let satoshiString = jsonDictionary["result"] as? String, let balance = bitcoin(from: satoshiString) else {
                return .failure(BlockexplorerError.invalidJSONData)
            }
            
            return .success(balance)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Private Methods
    static func transactionHistoryURL(for address: String) -> URL {
        return blockexplorerURL(method: .txlist, address: address)
    }
    
    static func balanceURL(for address: String) -> URL {
        return blockexplorerURL(method: .balance, address: address)
    }
    
}
