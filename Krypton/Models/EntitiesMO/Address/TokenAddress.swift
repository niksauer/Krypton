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
    private let blockchainConnector: BlockchainConnector = BlockchainService()
    
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
            }
        }
    }
    
    func updateTokens(completion: (() -> Void)?) {
        blockchainConnector.fetchTokens(for: self) { tokens, error in
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
