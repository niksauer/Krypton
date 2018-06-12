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
    private let bitcoinBlockExplorer: BitcoinBlockExplorer
    private let ethereumBlockExplorer: EthereumBlockExplorer
    
    // MARK: - Initialization
    init(bitcoinBlockExplorer: BitcoinBlockExplorer, ethereumBlockExplorer: EthereumBlockExplorer) {
        self.bitcoinBlockExplorer = bitcoinBlockExplorer
        self.ethereumBlockExplorer = ethereumBlockExplorer
    }
    
    // MARK: - BlockchainConnector
    func fetchBlockCount(for blockchain: Blockchain, completion: @escaping (UInt64?, Error?) -> Void) {
        switch blockchain {
        case .BTC:
            bitcoinBlockExplorer.fetchBlockCount(completion: completion)
        case .ETH:
            ethereumBlockExplorer.fetchBlockCount(completion: completion)
        }
    }
    
    func fetchBalance(for address: Address, completion: @escaping (Double?, Error?) -> Void) {
        switch address {
        case let address as Bitcoin:
            bitcoinBlockExplorer.fetchBalance(for: address, completion: completion)
        case let address as Ethereum:
            ethereumBlockExplorer.fetchBalance(for: address, completion: completion)
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
        }
    }

    func fetchTokenBalance(for address: TokenAddress, token: TokenFeatures, completion: @escaping (Double?, Error?) -> Void) {
        switch (address, token) {
        case let (address as Ethereum, token as ERC20Token):
            ethereumBlockExplorer.fetchTokenBalance(for: address, token: token, completion: completion)
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
        }
    }
    
    func fetchTransactionHistory(for address: Address, timeframe: TransactionHistoryTimeframe, completion: @escaping ([TransactionPrototype]?, Error?) -> Void) {
        switch address {
        case let address as Bitcoin:
            bitcoinBlockExplorer.fetchTransactionHistory(for: address) { history, error in
                guard let history = history else {
                    completion(nil, error!)
                    return
                }
                
                switch timeframe {
                case .sinceBlock(let blockNumber):
                    completion(history.filter({ $0.block >= blockNumber }), nil)
                default:
                    completion(history, nil)
                }
            }
        case let address as Ethereum:
            ethereumBlockExplorer.fetchTransactionHistory(for: address, type: .normal, timeframe: timeframe) { normalHistory, error in
                guard let normalHistory = normalHistory else {
                    completion(nil, error!)
                    return
                }
                
                self.ethereumBlockExplorer.fetchTransactionHistory(for: address, type: .internal, timeframe: timeframe) { internalHistory, error in
                    guard let internalHistory = internalHistory else {
                        completion(nil, error!)
                        return
                    }
                    
                    completion(normalHistory + internalHistory, nil)
                }
            }
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
            return
        }
    }
    
}
