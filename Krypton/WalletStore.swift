//
//  PriceStore.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class WalletStore {
    // MARK: - Private Properties
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Private Methods
    private func processTransactionHistoryRequest(data: Data?, error: Error?) -> TransactionHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return EtherscanAPI.transactionHistory(fromJSON: jsonData)
    }
    
    private func processBalanceRequest(data: Data?, error: Error?) -> BalanceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return EtherscanAPI.balance(fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    func fetchTransactionHistory(for address: String, type: TransactionHistoryType, completion: @escaping (TransactionHistoryResult) -> Void) {
        let url: URL
        
        switch type {
        case .normal:
            url = EtherscanAPI.transactionHistoryURL(for: address)
        case .contract:
            url = EtherscanAPI.internalTransactionHistoryURL(for: address)
        }
    
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processTransactionHistoryRequest(data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    func fetchBalance(for address: String, completion: @escaping (BalanceResult) -> Void) {
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
