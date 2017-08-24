//
//  EtherConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum TransactionHistoryType: String {
    case normal
    case contract
}

enum TransactionHistoryTimeframe {
    case allTime
    case sinceBlock(Int)
}

struct EtherConnector {
    // MARK: - Private Properties
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Private Methods
    private static func processTransactionHistoryRequest(type: TransactionHistoryType, data: Data?, error: Error?) -> TransactionHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return EtherscanAPI.transactionHistory(type: type, fromJSON: jsonData)
    }
    
    private static func processBalanceRequest(data: Data?, error: Error?) -> BalanceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return EtherscanAPI.balance(fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    static func fetchTransactionHistory(for address: Address, type: TransactionHistoryType, timeframe: TransactionHistoryTimeframe, completion: @escaping (TransactionHistoryResult) -> Void) {
        let url = EtherscanAPI.transactionHistoryURL(for: address.address!, type: type, timeframe: timeframe)
        let request = URLRequest(url: url)

        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processTransactionHistoryRequest(type: type, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    static func fetchBalance(for address: Address, completion: @escaping (BalanceResult) -> Void) {
        let url = EtherscanAPI.balanceURL(for: address.address!)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processBalanceRequest(data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
}
