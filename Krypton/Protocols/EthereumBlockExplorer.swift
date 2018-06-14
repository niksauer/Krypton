//
//  EthereumBlockExplorer.swift
//  Krypton
//
//  Created by Niklas Sauer on 12.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum EthereumTransactionHistoryType: String {
    case normal
    case `internal`
}

protocol EthereumTransactionPrototype: TransactionPrototype {
    var type: EthereumTransactionHistoryType { get }
    var isError: Bool { get }
}

protocol EthereumBlockExplorer {
    func fetchBlockCount(completion: @escaping (UInt64?, Error?) -> Void)
    func fetchBalance(for address: EthereumAddress, completion: @escaping (Double?, Error?) -> Void)
    func fetchTransactionHistory(for address: EthereumAddress, type: EthereumTransactionHistoryType, timeframe: TransactionHistoryTimeframe, completion: @escaping ([EthereumTransactionPrototype]?, Error?) -> Void)
}

protocol EthereumTokenExplorer {
    func fetchTokens(for address: EthereumAddress, completion: @escaping ([TokenProtoype]?, Error?) -> Void)
}
