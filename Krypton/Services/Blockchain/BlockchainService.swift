//
//  BlockchainService.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

struct BlockchainService: BlockExplorer, TokenExplorer {
    
    // MARK: - Private Properties
    private let bitcoinBlockExplorer: BitcoinBlockExplorer = BlockExplorerService()
    private let ethereumBlockExplorer: EthereumBlockExplorer = EtherscanService()
    private let ethereumTokenExplorer: EthereumTokenExplorer = EthplorerService()
    private let ethereumTokenOperationExplorer: EthereumTokenOperationExplorer = EtherscanService()
    
    // MARK: - BlockExplorer
    func fetchBlockCount(for blockchain: Blockchain, completion: @escaping (UInt64?, Error?) -> Void) {
        switch blockchain {
        case .Bitcoin:
            bitcoinBlockExplorer.fetchBlockCount(completion: completion)
        case .Ethereum:
            ethereumBlockExplorer.fetchBlockCount(completion: completion)
        }
    }
    
    func fetchBalance(for address: Address, completion: @escaping (Double?, Error?) -> Void) {
        switch address.blockchain {
        case .Bitcoin:
            bitcoinBlockExplorer.fetchBalance(for: address as! BitcoinAddress, completion: completion)
        case .Ethereum:
            ethereumBlockExplorer.fetchBalance(for: address as! EthereumAddress, completion: completion)
        }
    }
    
    func fetchTransactionHistory(for address: Address, timeframe: Timeframe, completion: @escaping ([TransactionPrototype]?, Error?) -> Void) {
        switch address.blockchain {
        case .Bitcoin:
            bitcoinBlockExplorer.fetchTransactionHistory(for: address as! BitcoinAddress) { transactions, error in
                guard let transactions = transactions else {
                    completion(nil, error!)
                    return
                }
                
                switch timeframe {
                case .sinceBlock(let blockNumber):
                    completion(transactions.filter({ $0.block >= blockNumber }), nil)
                default:
                    completion(transactions, nil)
                }
            }
        case .Ethereum:
            ethereumBlockExplorer.fetchTransactionHistory(for: address as! EthereumAddress, type: .normal, timeframe: timeframe) { normalTransactions, error in
                guard let normalTransactions = normalTransactions else {
                    completion(nil, error!)
                    return
                }
                
                self.ethereumBlockExplorer.fetchTransactionHistory(for: address as! EthereumAddress, type: .internal, timeframe: timeframe) { internalTransactions, error in
                    guard let internalTransactions = internalTransactions else {
                        completion(nil, error!)
                        return
                    }
                    
                    completion(normalTransactions + internalTransactions, nil)
                }
            }
        }
    }
    
    // MARK: - TokenExplorer
    func fetchTokens(for address: TokenAddress, completion: @escaping ([TokenProtoype]?, Error?) -> Void) {
        switch address.blockchain {
        case .Ethereum:
            ethereumTokenExplorer.fetchTokens(for: address as! EthereumAddress, completion: completion)
        default:
            fatalError()
        }
    }
    
    func fetchTokenOperations(for address: TokenAddress, token: Token, type: TokenOperationType, timeframe: Timeframe, completion: @escaping ([TokenOperationPrototype]?, Error?) -> Void) {
        switch address.blockchain {
        case .Ethereum:
            ethereumTokenOperationExplorer.fetchTokenOperations(for: address as! EthereumAddress, token: token, type: type, timeframe: timeframe, completion: completion)
            break
        default:
            fatalError()
        }
    }
    
}
