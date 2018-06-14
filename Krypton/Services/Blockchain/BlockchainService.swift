//
//  BlockchainService.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

struct BlockchainService: BlockchainConnector {
    
    // MARK: - Private Properties
    private let bitcoinBlockExplorer: BitcoinBlockExplorer = BlockExplorerService()
    private let ethereumBlockExplorer: EthereumBlockExplorer = EtherscanService()
    private let ethplorer: EthereumTokenExplorer = EthplorerService()
    
    // MARK: - BlockchainConnector
    func fetchBlockCount(for blockchain: Blockchain, completion: @escaping (UInt64?, Error?) -> Void) {
        switch blockchain {
        case .Bitcoin:
            bitcoinBlockExplorer.fetchBlockCount(completion: completion)
        case .Ethereum:
            ethereumBlockExplorer.fetchBlockCount(completion: completion)
        }
    }
    
    func fetchBalance(for address: Address, completion: @escaping (Double?, Error?) -> Void) {
        switch address {
        case let address as BitcoinAddress:
            bitcoinBlockExplorer.fetchBalance(for: address, completion: completion)
        case let address as EthereumAddress:
            ethereumBlockExplorer.fetchBalance(for: address, completion: completion)
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
        }
    }

//    func fetchTokenBalance(for address: TokenAddress, token: TokenFeatures, completion: @escaping (Double?, Error?) -> Void) {
//        switch (address, token) {
//        case let (address as EthereumAddress, token as ERC20Token):
//            ethereumBlockExplorer.fetchTokenBalance(for: address, token: token, completion: completion)
//        default:
//            completion(nil, BlockchainConnectorError.invalidBlockchain)
//        }
//    }
    
    func fetchTokens(for address: TokenAddress, completion: @escaping ([TokenProtoype]?, Error?) -> Void) {
        switch address {
        case let address as EthereumAddress:
            ethplorer.fetchTokens(for: address, completion: completion)
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
        }
    }
    
    func fetchTransactionHistory(for address: Address, timeframe: TransactionHistoryTimeframe, completion: @escaping ([TransactionPrototype]?, Error?) -> Void) {
        switch address {
        case let address as BitcoinAddress:
            bitcoinBlockExplorer.fetchTransactionHistory(for: address) { transactions, error in
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
        case let address as EthereumAddress:
            ethereumBlockExplorer.fetchTransactionHistory(for: address, type: .normal, timeframe: timeframe) { normalTransactions, error in
                guard let normalTransactions = normalTransactions else {
                    completion(nil, error!)
                    return
                }
                
                self.ethereumBlockExplorer.fetchTransactionHistory(for: address, type: .internal, timeframe: timeframe) { internalTransactions, error in
                    guard let internalTransactions = internalTransactions else {
                        completion(nil, error!)
                        return
                    }
                    
                    completion(normalTransactions + internalTransactions, nil)
                }
            }
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
            return
        }
    }
    
}
