//
//  BlockchainConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum BlockchainConnectorError: Error {
    case invalidBlockchain
}

enum TransactionHistoryType: String {
    case normal
    case contract
}

enum TransactionHistoryTimeframe {
    case allTime
    case sinceBlock(Int)
}

enum TransactionHistoryResult {
    case success([BlockchainConnector.Transaction])
    case failure(Error)
}

enum BalanceResult {
    case success(Double)
    case failure(Error)
}

struct BlockchainConnector {
    
    // MARK: - Private Properties
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Public Properties
    struct Transaction {
        let identifier: String
        let date: Date
        let amount: Double
        let from: String
        let to: String
        let type: TransactionHistoryType
        let block: Int
        let isError: Bool
        let feeAmount: Double
    }
    
    // MARK: - Public Methods
    static func fetchTransactionHistory(for address: Address, type: TransactionHistoryType, timeframe: TransactionHistoryTimeframe, completion: @escaping (TransactionHistoryResult) -> Void) {
        let url: URL
        
        switch address {
        case is Bitcoin:
            url = BlockExplorerAPI.transactionHistoryURL(for: address.identifier!)
        case is Ethereum:
            url = EtherscanAPI.transactionHistoryURL(for: address.identifier!, type: type, timeframe: timeframe)
        default:
            OperationQueue.main.addOperation {
                completion(.failure(BlockchainConnectorError.invalidBlockchain))
            }
            
            return
        }
        
        let request = URLRequest(url: url)

        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            var result: TransactionHistoryResult
            
            if let jsonData = data {
                switch address {
                case is Bitcoin:
                    result = BlockExplorerAPI.transactionHistory(fromJSON: jsonData, for: address)

                    if case TransactionHistoryResult.success(let transactions) = result, case TransactionHistoryTimeframe.sinceBlock(let blockNumber) = timeframe {
                        result = .success(transactions.filter { $0.block >= blockNumber })
                    }
                case is Ethereum:
                    result = EtherscanAPI.transactionHistory(type: type, fromJSON: jsonData)
                default:
                    return
                }
            } else {
                result = .failure(error!)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    static func fetchBalance(for address: Address, completion: @escaping (BalanceResult) -> Void) {
        let url: URL
        
        switch address {
        case is Bitcoin:
            url = BlockExplorerAPI.balanceURL(for: address.identifier!)
        case is Ethereum:
            url = EtherscanAPI.balanceURL(for: address.identifier!)
        default:
            OperationQueue.main.addOperation {
                completion(.failure(BlockchainConnectorError.invalidBlockchain))
            }
            
            return
        }
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result: BalanceResult
            
            if let jsonData = data {
                switch address {
                case is Bitcoin:
                    result = BlockExplorerAPI.balance(fromJSON: jsonData)
                case is Ethereum:
                    result = EtherscanAPI.balance(fromJSON: jsonData)
                default:
                    return
                }
            } else {
                result = .failure(error!)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }

    static func fetchTokenBalance(for address: TokenAddress, token: TokenFeatures, completion: @escaping (BalanceResult) -> Void) {
        let url: URL
        
        switch address {
        case is Ethereum:
            url = EtherscanAPI.tokenBalanceURL(for: address.identifier!, contractAddress: token.address)
        default:
            OperationQueue.main.addOperation {
                completion(.failure(BlockchainConnectorError.invalidBlockchain))
            }
            
            return
        }
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result: BalanceResult
            
            if let jsonData = data {
                switch address {
                case is Ethereum:
                    switch EtherscanAPI.tokenBalance(fromJSON: jsonData) {
                    case let .success(balance):
                        result = .success(balance * (pow(10, -Double(token.decimalDigits))))
                    case let .failure(error):
                        result = .failure(error)
                    }
                default:
                    return
                }
            } else {
                result = .failure(error!)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
}
