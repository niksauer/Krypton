//
//  TokenExplorer.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

protocol TokenProtoype {
    var balance: Double { get }
    var address: String { get }
    var name: String { get }
    var symbol: String { get }
    var decimalDigits: Int { get }
}

enum TokenOperationType: String {
    case transfer
}

protocol TokenOperationPrototype {
    var date: Date { get }
    var identifier: String { get }
    var type: TokenOperationType { get }
    var amount: Double { get }
    var from: String { get }
    var to: String { get }
    var block: Int { get }
}

protocol TokenExplorer {
    func fetchTokens(for address: TokenAddress, completion: @escaping ([TokenProtoype]?, Error?) -> Void)
    func fetchTokenOperations(for address: TokenAddress, token: Token, type: TokenOperationType, timeframe: Timeframe, completion: @escaping ([TokenOperationPrototype]?, Error?) -> Void)
}
