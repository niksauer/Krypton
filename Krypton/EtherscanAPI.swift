//
//  EtherscanAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum EtherscanError: Error {
    case invalidJSONData
}

enum TransactionHistoryResult {
    case success([EtherscanAPI.Transaction])
    case failure(Error)
}

enum BalanceResult {
    case success(Double)
    case failure(Error)
}

struct EtherscanAPI {
    
    // MARK: - Public Properties
    struct Transaction {
        let identifier: String
        let date: NSDate
        let amount: Double
        let from: String
        let to: String
        let type: TransactionHistoryType
        let block: Int32
    }
    
    // MARK: - Private Properties
    private static let baseURL = "https://api.etherscan.io/api"
    private static let apiKey = "N6I8XYMDAAKSTK9IW4G2BMSM837PHG6XFW"
    
    private enum Method: String {
        case txlist
        case txlistinternal
        case balance
    }
    
    // MARK: - Private Methods
    private static func etherscanURL(method: Method, parameters: [String: String]) -> URL {
        var components = URLComponents(string:  baseURL)!
        var queryItems = [URLQueryItem]()
        
        let module: String
        
        switch method {
        case .balance, .txlist, .txlistinternal:
            module = "account"
        }
        
        let baseParams = [
            "module" : module,
            "action" : method.rawValue,
            "apikey" : apiKey
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        for (key, value) in parameters {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    private static func transaction(type: TransactionHistoryType, fromJSON json: [String: Any]) -> Transaction? {
        guard let isErrorString = json["isError"] as? String, isErrorString != "1", let hashString = json["hash"] as? String, let timeString = json["timeStamp"] as? String, let time = Double(timeString), let weiString = json["value"] as? String, let amount = ether(from: weiString), let fromString = json["from"] as? String, let toString = json["to"] as? String, let blockString = json["blockNumber"] as? String, let block = Int32(blockString) else {
            return nil
        }
        
        return Transaction(identifier: hashString, date: NSDate(timeIntervalSince1970: time), amount: amount, from: fromString, to: toString, type: type, block: block)
    }
    
    private static func ether(from weiString: String) -> Double? {
        let missingLeadingZeros = 20-weiString.characters.count
        var valueString = weiString
        
        for _ in 0..<missingLeadingZeros {
            valueString = "0" + valueString
        }
        
        valueString.insert(".", at: valueString.index(valueString.startIndex, offsetBy: 2))

        return Double(valueString)
    }
    
    // MARK: - Public Methods
    static func transactionHistory(type: TransactionHistoryType, fromJSON data: Data) -> TransactionHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let transactionsArray = jsonDictionary["result"] as? [[String: Any]] else {
                return .failure(EtherscanError.invalidJSONData)
            }

            var transactionHistory = [Transaction]()
            
            for transactionJSON in transactionsArray {
                if let transaction = transaction(type: type, fromJSON: transactionJSON) {
                    transactionHistory.append(transaction)
                }
            }

            if transactionHistory.isEmpty && !transactionsArray.isEmpty {
                return .failure(EtherscanError.invalidJSONData)
            }
            
            return .success(transactionHistory)
        } catch let error {
            return .failure(error)
        }
    }
    
    static func balance(fromJSON data: Data) -> BalanceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let weiString = jsonDictionary["result"] as? String else {
                return .failure(EtherscanError.invalidJSONData)
            }
            
            if let balance = ether(from: weiString) {
                return .success(balance)
            } else {
                return .failure(EtherscanError.invalidJSONData)
            }
        } catch let error {
            return .failure(error)
        }
    }
    
    // https://etherscan.io/apis
    // <"blockNumber">, <"timeStamp">, <"hash">, <"nonce">, <"blockHash">, <"transactionIndex">, <"from">, <"to">, <"value">, <"gas">, <"gasPrice">, <"isError">, <"input">, <"contractAddress">, <"cumulativeGasUsed">, <"gasUsed">, <"confirmations">
    
    // <"blockNumber">, <"value">, <"isError">, <"ierrCode">, <"timeStamp">, <"contractAddress">, <"input">, <"hash">, <"type">, <"from">, <"to">, <"traceId">, <"to">, <"gasUsed">, <"gas">,
    static func transactionHistoryURL(for address: String, type: TransactionHistoryType, timeframe: TransactionHistoryTimeframe) -> URL {
        let method: Method
        
        switch type {
        case .normal:
            method = .txlist
        case .contract:
            method = .txlistinternal
        }
        
        let startBlock: Int
        
        switch timeframe {
        case .allTime:
            startBlock = 0
        case .sinceBlock(let blockNumber):
            startBlock = blockNumber
        }
        
        return etherscanURL(method: method, parameters: [
            "address": address,
            "startblock": String(startBlock),
            "endblock": "99999999",
            "sort": "asc",
        ])
    }
    
    static func balanceURL(for address: String) -> URL {
        return etherscanURL(method: .balance, parameters: [
            "address": address,
            "tag": "latest",
        ])
    }
}
