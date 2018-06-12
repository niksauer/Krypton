//
//  BitcoinBlockExplorer.swift
//  Krypton
//
//  Created by Niklas Sauer on 12.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

protocol BitcoinTransactionPrototype: TransactionPrototype {
    var amountFromSender: [String: Double] { get }
    var amountForReceiver: [String: Double] { get }
}

protocol BitcoinBlockExplorer {
    func fetchBlockCount(completion: @escaping (UInt64?, Error?) -> Void)
    func fetchBalance(for address: BitcoinAddress, completion: @escaping (Double?, Error?) -> Void)
    func fetchTransactionHistory(for address: BitcoinAddress, completion: @escaping ([BitcoinTransactionPrototype]?, Error?) -> Void)
}
