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
    
    // MARK: Management
    override func update(completion: (() -> Void)?) {
        super.update {
            self.updateTokenBalance {
                self.updateTokenExchangeRateHistory {
                    completion?()
                }
            }
        }
    }
    
    func updateTokenBalance(completion: (() -> Void)?) {
        guard let associatedTokens = self.blockchain.associatedTokens else {
            return
        }
        
        for (index, associatedToken) in associatedTokens.enumerated() {
            var updateCompletion: (() -> Void)? = nil
            
            if index == associatedTokens.count-1 {
                updateCompletion = completion
            }
            
            BlockchainConnector.fetchTokenBalance(for: self, token: associatedToken) { result in
                switch result {
                case .success(let balance):
                    let context = AppDelegate.viewContext
                    let token = self.storedTokens.filter({ $0.isEqual(to: associatedToken) }).first
                    
                    guard balance > 0 else {
                        if token != nil {
                            context.delete(token!)
                        }
                        
                        updateCompletion?()
                        return
                    }
                    
                    if let token = token {
                        do {
                            guard token.balance != balance else {
                                log.verbose("Balance of token '\(associatedToken.name)' for address '\(self.logDescription)' is already up-to-date.")
                                updateCompletion?()
                                return
                            }
                            
                            token.balance = balance
                            try context.save()
                            log.debug("Updated balance (\(balance) \(associatedToken.code) of token '\(associatedToken.name)' for address '\(self.logDescription)'.")
                            self.tokenDelegate?.didUpdateTokenBalance(for: self, token: token)
                            updateCompletion?()
                        } catch {
                            log.error("Failed to save fetched balance of token '\(associatedToken.name)' for address '\(self.logDescription)': \(error)")
                        }
                    } else {
                        do {
                            let token = try Token.createToken(from: associatedToken, owner: self, in: context)
                            token.balance = balance
                            try context.save()
                            log.info("Created token '\(associatedToken.name)' for address '\(self.logDescription)' with balance: \(balance) \(associatedToken.code)")
                            self.tokenDelegate?.didUpdateTokenBalance(for: self, token: token)
                            updateCompletion?()
                        } catch {
                            log.error("Failed to create token '\(associatedToken.name)' for address '\(self.logDescription)': \(error)")
                        }
                    }
                case .failure(let error):
                    log.error("Failed to fetch balance of token '\(associatedToken.name)' for address '\(self.logDescription)': \(error)")
                }
            }
        }
    }
    
    func updateTokenExchangeRateHistory(completion: (() -> Void)?) {
        if let firstTransaction = getOldestTransaction() {
            for (index, token) in storedTokens.enumerated() {
                var updateCompletion: (() -> Void)? = nil
                
                if index == storedTokens.count-1 {
                    updateCompletion = completion
                }
                
                ExchangeRate.updateExchangeRateHistory(for: token.currencyPair, since: firstTransaction.date!, completion: updateCompletion)
            }
        } else {
            log.debug("Exchange rate history is already up-to-date.")
            completion?()
        }
    }
    
    // MARK: Finance
    func getTokenExchangeValue(on date: Date) -> Double? {
        var value = 0.0
        
        for token in storedTokens {
            if let exchangeValue = token.getExchangeValue(on: date) {
                value = value + exchangeValue
            } else {
                return nil
            }
        }
        
        return value
    }
    
}

class Ethereum: TokenAddress {
    
    // MARK: - Initializers
    override func awakeFromInsert() {
        super.awakeFromInsert()
        blockchainRaw = Blockchain.ETH.rawValue
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
