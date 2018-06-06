//
//  BlockchainConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

enum BlockchainConnectorError: Error {
    case invalidBlockchain
}

enum TransactionHistoryTimeframe {
    case allTime
    case sinceBlock(Int)
}

enum TransactionHistoryResult {
    case success([TransactionPrototype])
    case failure(Error)
}

enum BalanceResult {
    case success(Double)
    case failure(Error)
}

enum BlockCountResult {
    case success(UInt64)
    case failure(Error)
}

protocol TransactionPrototype {
    var identifier: String { get }
    var date: Date { get }
    var totalAmount: Double { get }
    var feeAmount: Double { get }
    var block: Int { get }
    var from: [String] { get }
    var to: [String] { get }
    var isOutbound: Bool { get }
}

protocol EthereumTransactionPrototype: TransactionPrototype {
    var type: EthereumTransactionHistoryType { get }
    var isError: Bool { get }
}

protocol BitcoinTransactionPrototype: TransactionPrototype {
    var amountFromSender: [String: Double] { get }
    var amountForReceiver: [String: Double] { get }
}

enum EthereumTransactionHistoryType: String {
    case normal
    case `internal`
}

struct BlockchainConnector {
    
    // MARK: - Private Properties
    private static let session = URLSession(configuration: .default)
    
    // MARK: - Public Methods
    static func fetchTransactionHistory(for address: Address, timeframe: TransactionHistoryTimeframe, completion: @escaping (TransactionHistoryResult) -> Void) {
        let url: URL
        
        switch address {
        case is Bitcoin:
            url = BlockExplorerAPI.transactionHistoryURL(for: address.identifier!)
        case is Ethereum:
            url = EtherscanAPI.transactionHistoryURL(for: address.identifier!, type: .normal, timeframe: timeframe)
        default:
            completion(.failure(BlockchainConnectorError.invalidBlockchain))
            return
        }
        
        let request = URLRequest(url: url)

        let task = session.dataTask(with: request) { (data, response, error) in
            var result: TransactionHistoryResult
            
            guard let jsonData = data else {
                OperationQueue.main.addOperation {
                    completion(.failure(error!))
                }
                return
            }
            
            switch address {
            case is Bitcoin:
                result = BlockExplorerAPI.transactionHistory(fromJSON: jsonData, for: address.identifier!)
                
                if case TransactionHistoryResult.success(let transactions) = result, case TransactionHistoryTimeframe.sinceBlock(let blockNumber) = timeframe {
                    result = .success(transactions.filter { $0.block >= blockNumber })
                }
                
                OperationQueue.main.addOperation {
                    completion(result)
                }
            case is Ethereum:
                result = EtherscanAPI.transactionHistory(fromJSON: jsonData, for: address.identifier!, type: .normal)
                
                switch result {
                case .success(let normalTransactions):
                    let url = EtherscanAPI.transactionHistoryURL(for: address.identifier!, type: .internal, timeframe: timeframe)
                    let request = URLRequest(url: url)
                    
                    let task = session.dataTask(with: request) { (data, response, error) in
                        if let jsonData = data {
                            result = EtherscanAPI.transactionHistory(fromJSON: jsonData, for: address.identifier!, type: .internal)
                            
                            if case TransactionHistoryResult.success(let internalTransactions) = result {
                                result = .success(normalTransactions + internalTransactions)
                            }
                        } else {
                            result = .failure(error!)
                        }
                        
                        OperationQueue.main.addOperation {
                            completion(result)
                        }
                    }
                    
                    task.resume()
                case .failure(let error):
                    OperationQueue.main.addOperation {
                        completion(.failure(error))
                    }
                }
            default:
                return
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
            completion(.failure(BlockchainConnectorError.invalidBlockchain))
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
    
    static func fetchBlockCount(for blockchain: Blockchain, completion: @escaping (BlockCountResult) -> Void) {
        let url: URL
        
        switch blockchain {
        case .BTC:
            url = BlockExplorerAPI.blockCountURL()
        case .ETH:
            url = EtherscanAPI.blockCountURL()
        }
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result: BlockCountResult
            
            if let jsonData = data {
                switch blockchain {
                case .BTC:
                    result = BlockExplorerAPI.blockCount(fromJSON: jsonData)
                case .ETH:
                    result = EtherscanAPI.blockCount(fromJSON: jsonData)
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
