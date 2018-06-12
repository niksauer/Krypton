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

struct BlockchainConnector {
    
    // MARK: - Private Properties
    private let etherscanService: EtherscanService
    private let blockExplorer: BlockExplorerService
    
    // MARK: - Initialization
    init(etherscanService: EtherscanService, blockExplorer: BlockExplorerService) {
        self.etherscanService = etherscanService
        self.blockExplorer = blockExplorer
    }
    
    // MARK: - Public Methods
    func fetchBlockCount(for blockchain: Blockchain, completion: @escaping (UInt64?, Error?) -> Void) {
        switch blockchain {
        case .BTC:
            blockExplorer.getBlockCount(completion: completion)
        case .ETH:
            etherscanService.getBlockCount(completion: completion)
        }
    }
    
    func fetchBalance(for address: Address, completion: @escaping (Double?, Error?) -> Void) {
        switch address {
        case let address as Bitcoin:
            blockExplorer.getBalance(for: address, completion: completion)
        case let address as Ethereum:
            etherscanService.getBalance(for: address, completion: completion)
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
        }
    }

    func fetchTokenBalance(for address: TokenAddress, token: TokenFeatures, completion: @escaping (Double?, Error?) -> Void) {
        switch address {
        case let address as Ethereum:
            etherscanService.getTokenBalance(for: address, contractAddress: token.address, completion: completion)
        default:
            completion(nil, BlockchainConnectorError.invalidBlockchain)
        }
    }
    
    func fetchTransactionHistory(for address: Address, timeframe: TransactionHistoryTimeframe, completion: @escaping ([TransactionPrototype]?, Error?) -> Void) {
        switch address {
        case let address as Bitcoin:
            blockExplorer.getTransactionHistory(for: address) { history, error in
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
            etherscanService.getTransactionHistory(for: address, type: .normal, timeframe: timeframe) { normalHistory, error in
                guard let normalHistory = normalHistory else {
                    completion(nil, error!)
                    return
                }
                
                self.etherscanService.getTransactionHistory(for: address, type: .internal, timeframe: timeframe) { internalHistory, error in
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
