//
//  TokenAddress.swift
//  Krypton
//
//  Created by Niklas Sauer on 11.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

protocol TokenAddressDelegate {
    func tokenAddressDidRequestTokenExchangeRateHistoryUpdate(_ tokenAddress: TokenAddress)
    func tokenAddress(_ tokenAddress: TokenAddress, didUpdateBalanceForToken token: Token)
    func tokenAddress(_ tokenAddress: TokenAddress, didCreateNewToken token: Token)
}

class TokenAddress: Address {

    // MARK: - Private Properties
    private let context: NSManagedObjectContext = CoreDataStack.shared.viewContext
    private let blockchainConnector: BlockchainConnector = BlockchainService(bitcoinBlockExplorer: BlockExplorerService(hostURL: "https://blockexplorer.com", port: nil, credentials: nil), ethereumBlockExplorer: EtherscanService(hostURL: "https://api.etherscan.io", port: nil, credentials: nil))
    
    // MARK: - Public Properties
    var tokenDelegate: TokenAddressDelegate?
    
    var storedTokens: [Token] {
        return Array(tokens!) as! [Token]
    }
    
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
            
            blockchainConnector.fetchTokenBalance(for: self, token: associatedToken) { balance, error in
                guard let balance = balance else {
                    log.error("Failed to fetch balance of token '\(associatedToken.name)' for address '\(self.logDescription)': \(error!)")
                    updateCompletion?()
                    return
                }

                let token = self.storedTokens.filter({ $0.storedToken.isEqual(to: associatedToken) }).first

                guard balance > 0 else {
                    if let token = token {
                        do {
                            self.context.delete(token)
                            try self.context.save()
                            log.debug("Deleted token '\(associatedToken.name)' for address '\(self.logDescription)'.")
                        } catch {
                            log.debug("Failed to delete token '\(associatedToken.name)' for address '\(self.logDescription)': \(error)")
                        }
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
                        try self.context.save()
                        log.debug("Updated balance (\(balance) \(associatedToken.code) of token '\(associatedToken.name)' for address '\(self.logDescription)'.")
                        self.tokenDelegate?.tokenAddress(self, didUpdateBalanceForToken: token)
                        updateCompletion?()
                    } catch {
                        log.error("Failed to save fetched balance of token '\(associatedToken.name)' for address '\(self.logDescription)': \(error)")
                        updateCompletion?()
                    }
                } else {
                    do {
                        let token = try Token.createToken(from: associatedToken, owner: self, in: self.context)
                        token.balance = balance
                        try self.context.save()
                        log.info("Created token '\(associatedToken.name)' for address '\(self.logDescription)' with balance: \(balance) \(associatedToken.code)")
                        self.tokenDelegate?.tokenAddress(self, didCreateNewToken: token)
                        updateCompletion?()
                    } catch {
                        log.error("Failed to create token '\(associatedToken.name)' for address '\(self.logDescription)': \(error)")
                        updateCompletion?()
                    }
                }
            }
        }
    }
    
//    func updateTokenExchangeRateHistory(completion: (() -> Void)?) {
//        guard storedTokens.count > 0 else {
//            completion?()
//            return
//        }
//        
//        for (index, _) in storedTokens.enumerated() {
//            var updateCompletion: (() -> Void)? = nil
//            
//            if index == storedTokens.count-1 {
//                updateCompletion = {
//                    log.verbose("Updated token exchange rate histories for address '\(self.logDescription)'.")
//                    completion?()
//                }
//            }
//            
//            updateCompletion?()
//            
//            // use token transfer date
//            tokenDelegate?.tokenAddressDidRequestTokenExchangeRateHistoryUpdate(self)
//        }
//    }
    
}
