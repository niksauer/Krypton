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
        request.predicate = NSPredicate(format: "address = %@ AND owner = %@", token.address, self)
        
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
        self.updateTransactionHistory {
            self.updatePriceHistory {
                self.updateBalance {
                    self.updateTokenBalance {
                        completion?()
                    }
                }
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
            case let .success(txs):
                let context = AppDelegate.viewContext
                
                for txInfo in txs {
                    do {
                        let transaction = try Transaction.createTransaction(from: txInfo, owner: self, in: context)
                        
                        if transaction.block > self.lastBlock {
                            self.lastBlock = transaction.block + 1
                        }
                    } catch {
                        print("Failed to create transaction \(txInfo.identifier): \(error)")
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        print("Saved updated normal transaction history for \(self.identifier!).")
                    } else {
                        print("Normal transaction history for \(self.identifier!) is already up-to-date.")
                    }
                    
                    BlockchainConnector.fetchTransactionHistory(for: self, type: .contract, timeframe: timeframe, completion: { result in
                        switch result {
                        case let .success(txs):
                            for txInfo in txs {
                                do {
                                    let transaction = try Transaction.createTransaction(from: txInfo, owner: self, in: context)
                                    
                                    if transaction.block > self.lastBlock {
                                        self.lastBlock = transaction.block + 1
                                    }
                                } catch {
                                    print("Failed to create transaction \(txInfo.identifier): \(error)")
                                }
                            }
                            
                            do {
                                if context.hasChanges {
                                    try context.save()
                                    print("Saved updated contract transaction history for \(self.identifier!).")
                                } else {
                                    print("Contract transaction history for \(self.identifier!) is already up-to-date.")
                                }
                                
                                self.delegate?.didUpdateTransactionHistory(for: self)
                                completion?()
                            } catch {
                                print("Failed to save fetched contract transaction history for \(self.identifier!): \(error)")
                            }
                        case let .failure(error):
                            print("Failed to fetch contract transaction history for \(self.identifier!): \(error)")
                        }
                    })
                } catch {
                    print("Failed to save fetched normal transaction history for \(self.identifier!): \(error)")
                }
            case let .failure(error):
                print("Failed to fetch normal transaction history for \(self.identifier!): \(error)")
            }
        }
    }
    
    override func updateTokenBalance(completion: (() -> Void)?) {
        for etherToken in Token.ERC20.allValues {
            BlockchainConnector.fetchTokenBalance(for: self, token: etherToken, completion: { result in
                switch result {
                case let .success(balance):
                    let context = AppDelegate.viewContext
                    
                    if let token = self.getToken(etherToken) {
                        guard balance > 0 else {
                            context.delete(token)
                            completion?()
                            return
                        }
                        
                        do {
                            guard token.balance != balance else {
                                print("Balance for token \(etherToken.name) is already up-to-date.")
                                completion?()
                                return
                            }
                            
                            try context.save()
                            print("Saved updated balance for token \(etherToken.name).")
                            self.tokenDelegate?.didUpdateTokenBalance(for: self, token: token)
                            completion?()
                        } catch {
                            print("Failed to save updated token balance for \(etherToken.name): \(error)")
                        }
                    } else {
                        guard balance > 0 else {
                            completion?()
                            return
                        }
                        
                        do {
                            let token = try Token.createToken(from: etherToken, balance: balance, owner: self, in: context)
                            try context.save()
                            print("Created token \(etherToken.name) for \(self.identifier!) with balance: \(balance).")
                            self.tokenDelegate?.didUpdateTokenBalance(for: self, token: token)
                            completion?()
                        } catch {
                            print("Failed to create token \(etherToken.name): \(error)")
                        }
                    }
                case let .failure(error):
                    print("Failed to fetch token balance for \(etherToken.name): \(error)")
                }
            })
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
