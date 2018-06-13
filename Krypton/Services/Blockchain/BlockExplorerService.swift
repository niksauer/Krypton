//
//  BlockExplorerService.swift
//  Krypton
//
//  Created by Niklas Sauer on 29.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import NetworkKit

struct BlockExplorerService: JSONService, BitcoinBlockExplorer {
    
    // MARK: - Public Types
    struct Transaction: BitcoinTransactionPrototype {
        var identifier: String
        var date: Date
        var totalAmount: Double
        var feeAmount: Double
        var block: Int
        var from: [String]
        var to: [String]
        var isOutbound: Bool
        
        var amountFromSender: [String : Double]
        var amountForReceiver: [String : Double]
    }
    
    // MARK: - Service
    let client: JSONAPIClient
    
    init(hostURL: String, port: Int?, credentials: APICredentialStore?) {
        self.client = JSONAPIClient(hostURL: hostURL, port: port, basePath: "api", credentials: credentials)
    }

    // MARK: - Private Methods
    private func transaction(fromJSON json: [String: Any], for address: String) -> Transaction? {
        guard let hash = json["txid"] as? String, let time = json["time"] as? Double, let block = json["blockheight"] as? Int, let vin = json["vin"] as? [[String: Any]], let vout = json["vout"] as? [[String: Any]], let feeAmount = json["fees"] as? Double else {
            return nil
        }
        
        var senders = [String]()
        var receivers = [String]()
        
        var isOutbound = false
        var amount = 0.0
        
        var amountFromSender = [String: Double]()
        var amountForReceiver = [String: Double]()
        
        for input in vin {
            guard let sender = input["addr"] as? String, let inputAmount = input["value"] as? Double else {
                return nil
            }
            
            senders.append(sender)
            amountFromSender[sender] = inputAmount
            
            if sender.lowercased() == address.lowercased() {
                isOutbound = true
                amount = inputAmount
            }
        }
        
        for output in vout {
            guard let script = output["scriptPubKey"] as? [String: Any], let amountReceivers = script["addresses"] as? [String], let amountString = output["value"] as? String, let outputAmount = Double(amountString) else {
                return nil
            }
            
            receivers.append(contentsOf: amountReceivers)
            
            for receiver in amountReceivers {
                if receiver.lowercased() == address.lowercased() {
                    amount = amount + outputAmount
                }
                
                if let receiverAmount = amountForReceiver[receiver] {
                    amountForReceiver[receiver] = receiverAmount + outputAmount
                } else {
                    amountForReceiver[receiver] = outputAmount
                }
            }
        }
        
        return Transaction(identifier: hash, date: Date(timeIntervalSince1970: time), totalAmount: amount, feeAmount: feeAmount, block: block, from: senders, to: receivers, isOutbound: isOutbound, amountFromSender: amountFromSender, amountForReceiver: amountForReceiver)
    }
    
    // MARK: - BitcoinBlockExplorer
    func fetchBlockCount(completion: @escaping (UInt64?, Error?) -> Void) {
        client.makeGETRequest(to: "/status", params: [
            "q": "getBlockCount"
        ]) { result in
            let result = self.decode(UInt64.self, from: result, at: "blockcount")
            
            guard let blockCount = result.instance else {
                completion(nil, result.error!)
                return
            }
            
            completion(blockCount, nil)
        }
    }
    
    func fetchBalance(for address: BitcoinAddress, completion: @escaping (Double?, Error?) -> Void) {
//        client.ignoreJSONFormat = true
        
        client.makeGETRequest(to: "/addr/\(address.identifier!)/balance") { result in
            let result = self.getData(from: result)
            
            guard let data = result.instance else {
                completion(nil, result.error)
                return
            }
        
            guard let balanceString = String(data: data, encoding: .ascii), let balance = Double(balanceString) else {
                completion(nil, JSONAPIError.invalidData)
                return
            }

            completion(balance, nil)
        }
    }
    
    func fetchTransactionHistory(for address: BitcoinAddress, completion: @escaping ([BitcoinTransactionPrototype]?, Error?) -> Void) {
        client.makeGETRequest(to: "/txs", params: [
            "address": address.identifier!
        ]) { result in
            let result = self.getJSON(from: result)
            
            guard let json = result.json else {
                completion(nil, result.error)
                return
            }
            
            guard let transactionsArray = json["txs"] as? [[String: Any]] else {
                completion(nil, JSONAPIError.invalidJSON)
                return
            }
            
            var transactionHistory = [Transaction]()
            
            for transactionJSON in transactionsArray {
                if let transaction = self.transaction(fromJSON: transactionJSON, for: address.identifier!) {
                    transactionHistory.append(transaction)
                }
            }
            
            completion(transactionHistory, nil)
        }
    }

}
