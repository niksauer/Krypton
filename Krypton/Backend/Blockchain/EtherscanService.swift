//
//  EtherscanService.swift
//  Krypton
//
//  Created by Niklas Sauer on 12.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import NetworkKit

enum EthereumTransactionHistoryType: String {
    case normal
    case `internal`
}

protocol EthereumTransactionPrototype: TransactionPrototype {
    var type: EthereumTransactionHistoryType { get }
    var isError: Bool { get }
}

struct EtherscanService: JSONService {
    
    // MARK: - Public Types
    struct Transaction: EthereumTransactionPrototype {
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
    
    // MARK: - Service
    let client: JSONAPIClient
    
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
    
    private func transaction(fromJSON json: [String: Any], for address: String, type: EthereumTransactionHistoryType) -> Transaction? {
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
        
        return Transaction(identifier: hashString, date: Date(timeIntervalSince1970: time), totalAmount: amount, feeAmount: feeAmount, block: block, from: [fromString], to: [toString], isOutbound: isOutbound, isError: isError, type: type)
    }
    
    // MARK: - Public Methods
    func getBlockCount(completion: @escaping (UInt64?, Error?) -> Void) {
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
    
    func getBalance(for address: Ethereum, completion: @escaping (Double?, Error?) -> Void) {
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
    
    func getTokenBalance(for address: Ethereum, contractAddress: String, completion: @escaping (Double?, Error?) -> Void) {
        client.makeGETRequest(params: [
            "module": "account",
            "action": "tokenbalance",
            "apikey": apiKey,
            "contractaddress": contractAddress,
            "address": address.identifier!,
            "tag": "latest",
        ]) { result in
            let result = self.decode(String.self, from: result, at: "result")
            
            guard let balanceString = result.instance, let balance = Double(balanceString) else {
                completion(nil, result.error!)
                return
            }
            
            completion(balance, nil)
        }
    }

    func getTransactionHistory(for address: Ethereum, type: EthereumTransactionHistoryType, timeframe: TransactionHistoryTimeframe, completion: @escaping ([TransactionPrototype]?, Error?) -> Void) {
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
            
            var transactionHistory = [Transaction]()
            
            for transactionJSON in transactionsArray {
                if let transaction = self.transaction(fromJSON: transactionJSON, for: address.identifier!, type: type) {
                    transactionHistory.append(transaction)
                }
            }
            
            if transactionHistory.isEmpty && !transactionsArray.isEmpty {
                completion(nil, JSONAPIError.invalidJSON)
                return
            }
            
            completion(transactionHistory, nil)
        }
    }
    
}
