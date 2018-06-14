//
//  EtherscanService.swift
//  Krypton
//
//  Created by Niklas Sauer on 12.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import NetworkKit

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

struct EtherscanService: JSONService, EthereumBlockExplorer {
    
    // MARK: - Service
    let client: JSONAPIClient
    
    init() {
        self.init(hostURL: "https://api.etherscan.io", port: nil, credentials: nil)
    }
    
    init(hostURL: String, port: Int?, credentials: APICredentialStore?) {
        self.client = JSONAPIClient(hostURL: hostURL, port: port, basePath: "api", credentials: credentials)
    }
    
    // MARK: - Private Properties
    private let apiKey = "N6I8XYMDAAKSTK9IW4G2BMSM837PHG6XFW"
    
    // MARK: - Private Methods
    private func ether(from weiString: String) -> Double? {
        let missingLeadingZeros = 20-weiString.count
        var valueString = weiString
        
        for _ in 0..<missingLeadingZeros {
            valueString = "0" + valueString
        }
        
        valueString.insert(".", at: valueString.index(valueString.startIndex, offsetBy: 2))
        
        return Double(valueString)
    }
    
    private func transaction(fromJSON json: [String: Any], for address: String, type: EthereumTransactionHistoryType) -> EtherscanTransaction? {
        guard let isErrorString = json["isError"] as? String, let hashString = json["hash"] as? String, let timeString = json["timeStamp"] as? String, let time = Double(timeString), let weiString = json["value"] as? String, let amount = ether(from: weiString), let fromString = json["from"] as? String, let toString = json["to"] as? String, let blockString = json["blockNumber"] as? String, let block = Int(blockString) else {
            return nil
        }
        
        let isError = (isErrorString == "1")
        let isOutbound = (fromString.lowercased() == address.lowercased())
        
        var feeAmount = 0.0
        var totalAmount = amount
        
        if type == .normal {
            guard let gasUsedString = json["gasUsed"] as? String, let gasUsed = Double(gasUsedString), let gasPriceString = json["gasPrice"] as? String, let gasPrice = ether(from: gasPriceString) else {
                return nil
            }
            
            feeAmount = gasPrice * gasUsed
            
            if isOutbound {
                totalAmount = totalAmount + feeAmount
            }
        }
        
        return EtherscanTransaction(identifier: hashString, date: Date(timeIntervalSince1970: time), totalAmount: amount, feeAmount: feeAmount, block: block, from: [fromString], to: [toString], isOutbound: isOutbound, isError: isError, type: type)
    }
    
    // MARK: - EthereumBlockExplorer
    func fetchBlockCount(completion: @escaping (UInt64?, Error?) -> Void) {
        client.makeGETRequest(params: [
            "module": "proxy",
            "action": "eth_blockNumber",
            "apikey": apiKey
        ]) { result in
            let result = self.decode(String.self, from: result, at: "result")
            
            guard let blockCountString = result.instance, let blockCount = UInt64(blockCountString.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
                completion(nil, result.error!)
                return
            }
            
            completion(blockCount, nil)
        }
    }
    
    func fetchBalance(for address: EthereumAddress, completion: @escaping (Double?, Error?) -> Void) {
        client.makeGETRequest(params: [
            "module": "account",
            "action": "balance",
            "apikey": apiKey,
            "address": address.identifier!,
            "tag": "latest",
        ]) { result in
            let result = self.decode(String.self, from: result, at: "result")
            
            guard let weiString = result.instance, let balance = self.ether(from: weiString) else {
                completion(nil, result.error!)
                return
            }
        
            completion(balance, nil)
        }
    }
    
//    func fetchTokenBalance(for address: EthereumAddress, token: ERC20Token, completion: @escaping (Double?, Error?) -> Void) {
//        client.makeGETRequest(params: [
//            "module": "account",
//            "action": "tokenbalance",
//            "apikey": apiKey,
//            "contractaddress": token.address,
//            "address": address.identifier!,
//            "tag": "latest",
//        ]) { result in
//            let result = self.decode(String.self, from: result, at: "result")
//
//            guard let balanceString = result.instance, var balance = Double(balanceString) else {
//                completion(nil, result.error!)
//                return
//            }
//
//            balance = balance * (pow(10, -Double(token.decimalDigits)))
//
//            completion(balance, nil)
//        }
//    }

    func fetchTransactionHistory(for address: EthereumAddress, type: EthereumTransactionHistoryType, timeframe: TransactionHistoryTimeframe, completion: @escaping ([EthereumTransactionPrototype]?, Error?) -> Void) {
        let method: String
        
        switch type {
        case .normal:
            method = "txlist"
        case .`internal`:
            method = "txlistinternal"
        }
        
        let startBlock: Int
        
        switch timeframe {
        case .allTime:
            startBlock = 0
        case .sinceBlock(let blockNumber):
            startBlock = blockNumber
        }
        
        client.makeGETRequest(params: [
            "module": "account",
            "action": method,
            "apikey": apiKey,
            "address": address.identifier!,
            "startblock": String(startBlock),
            "endblock": "99999999",
            "sort": "asc",
        ]) { result in
            let result = self.getJSON(from: result)
            
            guard let json = result.json else {
                completion(nil, result.error!)
                return
            }
            
            guard let transactionsArray = json["result"] as? [[String: Any]] else {
                completion(nil, JSONAPIError.invalidJSON)
                return
            }
            
            var transactions = [EtherscanTransaction]()
            
            for transactionJSON in transactionsArray {
                if let transaction = self.transaction(fromJSON: transactionJSON, for: address.identifier!, type: type) {
                    transactions.append(transaction)
                }
            }
            
            if transactions.isEmpty && !transactionsArray.isEmpty {
                completion(nil, JSONAPIError.invalidJSON)
                return
            }
            
            completion(transactions, nil)
        }
    }
    
}
