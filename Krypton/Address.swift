//
//  Address.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum AddressError: Error {
    case duplicate
}

class Address: NSManagedObject {
    
    // MARK: - Class Methods
    /// returns new address if non-existent in database, throws otherwise
    class func createAddress(_ addressString: String, unit: Currency.Crypto, in context: NSManagedObjectContext) throws -> Address {
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        request.predicate = NSPredicate(format: "address = %@", addressString)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Address.addAddress -- Database Inconsistency")
                throw AddressError.duplicate
            }
        } catch {
            throw error
        }
        
        let address = Address(context: context)
        address.address = addressString
        address.cryptoCurrency = unit.rawValue
        
        return address
    }
    
    // MARK: - Public Methods
    /// fetches and saves balance retrieved via EtherscanAPI
    func updateBalance(in context: NSManagedObjectContext) {
        EtherConnector.fetchBalance(for: self, completion: { result in
            switch result {
            case let .success(balance):
                self.balance = balance
                
                do {
                    if context.hasChanges {
                        try context.save()
                        print("Saved updated balance.")
                    }
                } catch {
                    print("Failed to save fetched balance: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch balance: \(error)")
            }
        })
    }
    
    /// fetches and saves transaction history retrieved via EtherscanAPI
    func updateTransactionHistory(in context: NSManagedObjectContext) {
        let timeframe: TransactionHistoryTimeframe
        
        if lastBlock == 0 {
            timeframe = TransactionHistoryTimeframe.allTime
        } else {
            timeframe = TransactionHistoryTimeframe.sinceBlock(Int(lastBlock))
        }
        
        EtherConnector.fetchTransactionHistory(for: self, type: .normal, timeframe: timeframe, completion: { result in
            switch result {
            case let .success(txs):
                for txInfo in txs {
                    do {
                        let transaction = try Transaction.createTransaction(from: txInfo, in: context)
                        self.addToTransactions(transaction)
                        
                        if transaction.block > self.lastBlock {
                            self.lastBlock = transaction.block + 1 
                        }
                    } catch {
                        print("Failed to create transaction from: \(txInfo.identifier, error)")
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        print("Saved updated normal transaction history.")
                    }
                } catch {
                    print("Failed to save fetched normal transaction history: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch normal transaction history: \(error)")
            }
        })
        
        EtherConnector.fetchTransactionHistory(for: self, type: .contract, timeframe: timeframe, completion: { result in
            switch result {
            case let .success(txs):
                for txInfo in txs {
                    do {
                        let transaction = try Transaction.createTransaction(from: txInfo, in: context)
                        self.addToTransactions(transaction)
                        
                        if transaction.block > self.lastBlock {
                            self.lastBlock = transaction.block + 1
                        }
                    } catch {
                        print("Failed to create transaction from: \(txInfo.identifier, error)")
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        print("Saved updated contract transaction history.")
                    }
                } catch {
                    print("Failed to save fetched contract transaction history: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch contract transaction history: \(error)")
            }
        })
    }
    
    func firstTransaction() -> Transaction? {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "owner = %@", self)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        request.fetchLimit = 1
        
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

}
