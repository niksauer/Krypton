//
//  BlockExplorer.swift
//  Krypton
//
//  Created by Niklas Sauer on 12.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum BlockchainConnectorError: Error {
    case invalidBlockchain
}

enum Timeframe {
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

protocol BlockExplorer {
    func fetchBlockCount(for blockchain: Blockchain, completion: @escaping (UInt64?, Error?) -> Void)
    func fetchBalance(for address: Address, completion: @escaping (Double?, Error?) -> Void)
    func fetchTransactionHistory(for address: Address, timeframe: Timeframe, completion: @escaping ([TransactionPrototype]?, Error?) -> Void)
}


