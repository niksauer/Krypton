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
    private let tokenExplorer: TokenExplorer = BlockchainService()
    
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
            self.updateTokens {
                completion?()
//                self.updateTokenOperations {
//                    self.tokenDelegate?.tokenAddressDidRequestTokenExchangeRateHistoryUpdate(self)
//                    completion?()
//                }
            }
        }
    }
    
    func updateTokens(completion: (() -> Void)?) {
        tokenExplorer.fetchTokens(for: self) { tokens, error in
            guard let tokens = tokens else {
                log.error("Failed to fetch tokens for address '\(self.logDescription)': \(error!)")
                completion?()
                return
            }
            
            let tokenResults: [(token: Token, isNew: Bool)] = tokens.compactMap({
                do {
                    let tokenResult = try Token.createOrUpdate(from: $0, owner: self, in: self.context)
                    
                    if tokenResult.token.balance == 0 {
                        self.context.delete(tokenResult.token)
                        return nil
                    } else {
                        return tokenResult
                    }
                } catch {
                    log.error("Failed to create token '\($0.address)' for address '\(self.logDescription)': \(error)")
                    return nil
                }
            })

            let coreTokens = tokenResults.compactMap({ $0.token })
            self.addToTokens(NSSet(array: coreTokens))
            
            do {
                try self.context.save()
                log.debug("Updates tokens for address '\(self.logDescription)'.")
                
                for result in tokenResults {
                    guard result.isNew else {
                        continue
                    }
                    
                    self.tokenDelegate?.tokenAddress(self, didCreateNewToken: result.token)
                }
                
                completion?()
            } catch {
                log.error("Failed to save updated/created tokens for address '\(self.logDescription)': \(error)")
                completion?()
            }
        }
    }
    
    func updateTokenOperations(completion: (() -> Void)?) {
        guard storedTokens.count > 0 else {
            completion?()
            return
        }
        
        for (index, token) in storedTokens.enumerated() {
            var updateCompletion: (() -> Void)? = nil
            
            if index == storedTokens.count-1 {
                updateCompletion = {
                    log.verbose("Updated token operations for address '\(self.logDescription)'.")
                    completion?()
                }
            }
            
            let timeframe: Timeframe
            
            if lastBlock == 0 {
                timeframe = .allTime
            } else {
                timeframe = .sinceBlock(Int(lastTokenBlock))
            }
            
            tokenExplorer.fetchTokenOperations(for: self, token: token, type: .transfer, timeframe: timeframe) { operations, error in
                guard let operations = operations else {
                    log.error("Failed to fetch operations of token '\(token.logDescription)' for address '\(self.logDescription)': \(error!)")
                    updateCompletion?()
                    return
                }
                
                var newOperationsCount = 0
                
                for operationPrototype in operations {
                    do {
                        let _ = try TokenOperation.create(from: operationPrototype, token: token, in: self.context)
                        newOperationsCount = newOperationsCount + 1
                        
                        if operationPrototype.block > self.lastTokenBlock {
                            self.lastTokenBlock = Int64(operationPrototype.block + 1)
                        }
                    } catch {
                        switch error {
                        case TokenOperationError.duplicate:
                            break
                        default:
                            log.error("Failed to create operation '\(operationPrototype.identifier)' of token '\(token.logDescription)' for address '\(self.logDescription)': \(error)")
                        } 
                    }
                }
                
                token.lastUpdate = Date()
                
                do {
                    guard newOperationsCount > 0 else {
                        log.verbose("Operations of token \(token.logDescription)' for address '\(self.logDescription)' is already up-to-date.")
                        completion?()
                        return
                    }
                    
                    try self.context.save()
                    let multiple = (newOperationsCount >= 2) || (newOperationsCount == 0)
                    log.debug("Updated operations of token \(token.logDescription)' for address '\(self.logDescription)' with \(newOperationsCount) new transaction\(multiple ? "s" : "").")
                    completion?()
                } catch {
                    log.error("Failed to save fetched operations of token \(token.logDescription)' for address '\(self.logDescription)': \(error)")
                    completion?()
                }
            }
        }

    }
    
}
