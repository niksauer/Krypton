//
//  EtherConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct EtherConnector {
    // MARK: - Private Properties
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Private Methods
    private static func processTransactionHistoryRequest(for address: String, type: TransactionHistoryType, data: Data?, error: Error?) -> TransactionHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return EtherscanAPI.transactionHistory(for: address, type: type, fromJSON: jsonData)
    }
    
    private static func processBalanceRequest(data: Data?, error: Error?) -> BalanceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return EtherscanAPI.balance(fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    static func fetchTransactionHistory(for address: String, type: TransactionHistoryType, completion: @escaping (TransactionHistoryResult) -> Void) {
        let url = EtherscanAPI.transactionHistoryURL(for: address, type: type)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processTransactionHistoryRequest(for: address, type: type, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    static func fetchBalance(for address: String, completion: @escaping (BalanceResult) -> Void) {
        let url = EtherscanAPI.balanceURL(for: address)
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
