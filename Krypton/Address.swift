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
    /// creates and returns an address if non-existent in database, throws otherwise
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

    // MARK: - Public Properties
    /// returns the oldest transaction associated with an address
    var oldestTransaction: Transaction? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "owner = %@", self)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        request.fetchLimit = 1
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                return matches[0]
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    // MARK: - Public Methods
    /// fetches and saves balance
    func updateBalance(in context: NSManagedObjectContext) {
        BlockchainConnector.fetchBalance(for: self, completion: { result in
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
    
    /// fetches and saves transaction history since last retrieved block, executes completion block if no error is thrown
    func updateTransactionHistory(in context: NSManagedObjectContext, completion: (() -> Void)?) {
        let timeframe: TransactionHistoryTimeframe
        
        if lastBlock == 0 {
            timeframe = .allTime
        } else {
            timeframe = .sinceBlock(Int(lastBlock))
        }
        
        BlockchainConnector.fetchTransactionHistory(for: self, type: .normal, timeframe: timeframe, completion: { result in
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
                        
                        BlockchainConnector.fetchTransactionHistory(for: self, type: .contract, timeframe: timeframe, completion: { result in
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
                                        
                                        if let completion = completion {
                                            completion()
                                        }
                                    }
                                } catch {
                                    print("Failed to save fetched contract transaction history: \(error)")
                                }
                            case let .failure(error):
                                print("Failed to fetch contract transaction history: \(error)")
                            }
                        })
                    }
                } catch {
                    print("Failed to save fetched normal transaction history: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch normal transaction history: \(error)")
            }
        })
    }
    
    /// updates price history for trading pair associated with address starting from earliest transaction date encountered
    func updatePriceHistory() {
        if let cryptoCurrency = Currency.Crypto(rawValue: cryptoCurrency!), let tradingPair = Currency.getTradingPair(cryptoCurrency: cryptoCurrency, fiatCurrency: Wallet.baseCurrency), let firstTransactionDate = oldestTransaction?.date {
            TickerPrice.updatePriceHistory(for: tradingPair, since: firstTransactionDate as Date)
        }
    }

}
