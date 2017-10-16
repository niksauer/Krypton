//
//  TokenAddress.swift
//  Krypton
//
//  Created by Niklas Sauer on 11.10.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData
import SwiftKeccak

protocol TokenAddressDelegate {
    func didUpdateTokenBalance(for address: Address, token: Token)
}

class TokenAddress: Address {
    
    // MARK: - Public Properties
    var tokenDelegate: TokenAddressDelegate?
    
    var storedTokens: [Token] {
        return Array(tokens!) as! [Token]
    }
    
    // MARK: - Public Methods
    func getToken(_ token: TokenFeatures) -> Token? {
        let request: NSFetchRequest<Token> = Token.fetchRequest()
        request.predicate = NSPredicate(format: "currencyCode = %@ AND owner = %@", token.code, self)
        
        do {
            let matches = try AppDelegate.viewContext.fetch(request)
            if matches.count > 0 {
                return matches[0]
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    // MARK: Management
    override func update(completion: (() -> Void)?) {
        super.update {
            self.updateTokenBalance {
                completion?()
            }
        }
    }
    
    func updateTokenBalance(completion: (() -> Void)?) {
        preconditionFailure("This method must be overridden")
    }
    
}

class Ethereum: TokenAddress {
    
    // MARK: - Initializers
    override func awakeFromInsert() {
        super.awakeFromInsert()
        blockchainRaw = Blockchain.ETH.rawValue
    }
    
    // MARK: - Public Methods
    // MARK: Management
    override func updateTransactionHistory(completion: (() -> Void)?) {
        let timeframe: TransactionHistoryTimeframe
        
        if lastBlock == 0 {
            timeframe = .allTime
        } else {
            timeframe = .sinceBlock(Int(lastBlock))
        }
        
        BlockchainConnector.fetchTransactionHistory(for: self, type: .normal, timeframe: timeframe) { result in
            switch result {
            case .success(let txs):
                let context = AppDelegate.viewContext
                var newNormalTxCount = 0
                
                for txInfo in txs {
                    do {
                        let transaction = try Transaction.createTransaction(from: txInfo, owner: self, in: context)
                        newNormalTxCount = newNormalTxCount + 1
                        
                        if transaction.block > self.lastBlock {
                            self.lastBlock = transaction.block + 1
                        }
                    } catch {
                        log.error("Failed to create transaction '\(txInfo.identifier)' for address '\(self.logDescription)': \(error)")
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        let multipleNormalTx = newNormalTxCount >= 2 || newNormalTxCount == 0
                        log.debug("Updated normal transaction history for address '\(self.logDescription)' with \(newNormalTxCount) new transaction\(multipleNormalTx ? "s" : "").")
                    } else {
                        log.verbose("Normal transaction history for address '\(self.logDescription)' is already up-to-date.")
                    }
                    
                    BlockchainConnector.fetchTransactionHistory(for: self, type: .`internal`, timeframe: timeframe) { result in
                        switch result {
                        case .success(let txs):
                            var newInternalTxCount = 0
                            
                            for txInfo in txs {
                                do {
                                    let transaction = try Transaction.createTransaction(from: txInfo, owner: self, in: context)
                                    newInternalTxCount = newInternalTxCount + 1
                                    
                                    if transaction.block > self.lastBlock {
                                        self.lastBlock = transaction.block + 1
                                    }
                                } catch {
                                    log.error("Failed to create transaction '\(txInfo.identifier)' for address '\(self.logDescription)': \(error)")
                                }
                            }
                            
                            do {
                                if context.hasChanges {
                                    try context.save()
                                    let multipleInternalTx = newInternalTxCount >= 2 || newInternalTxCount == 0
                                    log.debug("Updated internal transaction history for address '\(self.logDescription)' with \(newInternalTxCount) new transaction\(multipleInternalTx ? "s" : "").")
                                } else {
                                    log.verbose("Internal transaction history for address '\(self.logDescription)' is already up-to-date.")
                                }
                                
                                self.delegate?.didUpdateTransactionHistory(for: self)
                                completion?()
                            } catch {
                                log.error("Failed to save fetched internal transaction history for address '\(self.logDescription)': \(error)")
                            }
                        case .failure(let error):
                            log.error("Failed to fetch internal transaction history for address '\(self.logDescription)': \(error)")
                        }
                    }
                } catch {
                    log.error("Failed to save fetched normal transaction history for address '\(self.logDescription)': \(error)")
                }
            case .failure(let error):
                log.error("Failed to fetch normal transaction history for address '\(self.logDescription)': \(error)")
            }
        }
    }
    
    override func updateTokenBalance(completion: (() -> Void)?) {
        for etherToken in Token.ERC20.allValues {
            BlockchainConnector.fetchTokenBalance(for: self, token: etherToken) { result in
                switch result {
                case .success(let balance):
                    let context = AppDelegate.viewContext
                    
                    guard balance > 0 else {
                        if let token = self.getToken(etherToken) {
                            context.delete(token)
                        }
                        completion?()
                        return
                    }
                    
                    if let token = self.getToken(etherToken) {
                        do {
                            guard token.balance != balance else {
                                log.verbose("Balance of token '\(etherToken.name)' is already up-to-date.")
                                completion?()
                                return
                            }
                            
                            token.address = etherToken.address
                            token.balance = balance
                            try context.save()
                            log.debug("Updated balance (\(balance) \(etherToken.code) of token '\(etherToken.name)' for address '\(self.logDescription)'.")
                            self.tokenDelegate?.didUpdateTokenBalance(for: self, token: token)
                            completion?()
                        } catch {
                            log.error("Failed to save fetched balance of token '\(etherToken.name)' for address '\(self.logDescription)': \(error)")
                        }
                    } else {
                        do {
                            let token = try Token.createToken(from: etherToken, owner: self, in: context)
                            token.balance = balance
                            try context.save()
                            log.info("Created token '\(etherToken.name)' for address '\(self.logDescription)' with balance: \(balance) \(etherToken.code)")
                            self.tokenDelegate?.didUpdateTokenBalance(for: self, token: token)
                            completion?()
                        } catch {
                            log.error("Failed to create token '\(etherToken.name)' for address '\(self.logDescription)': \(error)")
                        }
                    }
                case .failure(let error):
                    log.error("Failed to fetch balance of token '\(etherToken.name)' for address '\(self.logDescription)': \(error)")
                }
            }
        }
    }
    
    // MARK: Cryptography
    override func isValidAddress() -> Bool {
        let allLowerCapsTest = NSPredicate(format: "SELF MATCHES %@", "(0x)?[0-9a-f]{40}")
        let allUpperCapsTest = NSPredicate(format: "SELF MATCHES %@", "(0x)?[0-9A-F]{40}")
        
        if !allLowerCapsTest.evaluate(with: identifier!.lowercased()) {
            // basic requirements
            return false
        } else if allLowerCapsTest.evaluate(with: identifier!) || allUpperCapsTest.evaluate(with: identifier!) {
            // either all lower or upper case
            return true
        } else {
            // checksum address
            let address = identifier!.replacingOccurrences(of: "0x", with: "")
            let addressHash = keccak256(address.lowercased()).hexEncodedString()
            
            for (index, character) in address.enumerated() {
                guard let hashDigit = Int(String(addressHash[index]), radix: 16) else {
                    return false
                }
                
                let digit = String(character)
                let uppercaseDigit = String(digit).uppercased()
                let lowercaseDigit = String(digit).lowercased()
                
                if hashDigit > 7 && uppercaseDigit != digit || hashDigit <= 7 && lowercaseDigit != digit {
                    return false
                }
            }
            
            return true
        }
    }
        
}
