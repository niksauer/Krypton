//
//  TokenAddress.swift
//  Krypton
//
//  Created by Niklas Sauer on 11.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData
import SwiftKeccak

protocol TokenAddressDelegate {
    func tokenAddressDidRequestTokenExchangeRateHistoryUpdate(_ tokenAddress: TokenAddress)
    func tokenAddress(_ tokenAddress: TokenAddress, didUpdateBalanceForToken token: Token)
}

class TokenAddress: Address {
    
    // MARK: - Public Properties
    var tokenDelegate: TokenAddressDelegate?
    
    var storedTokens: [Token] {
        return Array(tokens!) as! [Token]
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext = CoreDataStack.shared.viewContext
    
    // MARK: - Initialization
    override func awakeFromFetch() {
        super.awakeFromFetch()
        tokenDelegate = portfolio
        log.debug("Set portfolio '\(portfolio!.logDescription)' as delegate of address '\(logDescription)'.")
    }
    
    // MARK: Management
    override func update(completion: (() -> Void)?) {
        super.update {
            self.updateTokenBalance {
                self.tokenDelegate?.tokenAddressDidRequestTokenExchangeRateHistoryUpdate(self)
                completion?()
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
                updateCompletion = {
                    log.verbose("Updated tokens for address '\(self.logDescription)'.")
                    completion?()
                }
            }
            
            BlockchainConnector.fetchTokenBalance(for: self, token: associatedToken) { result in
                switch result {
                case .success(let balance):
                    let token = self.storedTokens.filter({ $0.isEqual(to: associatedToken) }).first
                    
                    guard balance > 0 else {
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
                            try self.context.save()
                            log.debug("Updated balance (\(balance) \(associatedToken.code) of token '\(associatedToken.name)' for address '\(self.logDescription)'.")
                            self.tokenDelegate?.tokenAddress(self, didUpdateBalanceForToken: token)
                            updateCompletion?()
                        } catch {
                            log.error("Failed to save fetched balance of token '\(associatedToken.name)' for address '\(self.logDescription)': \(error)")
                        }
                    } else {
                        do {
                            let token = try Token.createToken(from: associatedToken, owner: self, in: self.context)
                            token.balance = balance
                            try self.context.save()
                            log.info("Created token '\(associatedToken.name)' for address '\(self.logDescription)' with balance: \(balance) \(associatedToken.code)")
                            self.tokenDelegate?.tokenAddress(self, didUpdateBalanceForToken: token)
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
        if storedTokens.count > 0 {
            for (index, _) in storedTokens.enumerated() {
                var updateCompletion: (() -> Void)? = nil
                
                if index == storedTokens.count-1 {
                    updateCompletion = {
                        log.verbose("Updated token exchange rate histories for address '\(self.logDescription)'.")
                        completion?()
                    }
                }
                
                updateCompletion?()
                
                // use token transfer date
//                ExchangeRate.updateExchangeRateHistory(for: token.currencyPair, since: firstTransaction.date!, completion: updateCompletion)
            }
        } else {
            completion?()
        }
    }
    
}

class Ethereum: TokenAddress {
    
    // MARK: - Initializers
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Blockchain.ETH.rawValue, forKey: "blockchainRaw")
    }
    
    // MARK: - Public Methods
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
