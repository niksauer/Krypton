//
//  BlockchainConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 12.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
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

protocol TokenProtoype {
    var balance: Double { get }
    var address: String { get }
    var name: String { get }
    var symbol: String { get }
    var decimalDigits: Int { get }
}

protocol BlockchainConnector {
    func fetchBlockCount(for blockchain: Blockchain, completion: @escaping (UInt64?, Error?) -> Void)
    func fetchBalance(for address: Address, completion: @escaping (Double?, Error?) -> Void)
    func fetchTokens(for address: TokenAddress, completion: @escaping ([TokenProtoype]?, Error?) -> Void)
    func fetchTransactionHistory(for address: Address, timeframe: TransactionHistoryTimeframe, completion: @escaping ([TransactionPrototype]?, Error?) -> Void)
}
