//
//  EtherscanTransaction.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct EtherscanTransaction: EthereumTransactionPrototype {
    var identifier: String
    var date: Date
    var totalAmount: Double
    var feeAmount: Double
    var block: Int
    var from: [String]
    var to: [String]
    var isOutbound: Bool
    
    var isError: Bool
    var type: EthereumTransactionHistoryType
}
