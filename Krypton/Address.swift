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
    
    // MARK: - Public Class Methods
    /// creates and returns address if non-existent in database, throws otherwise
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
    /// delegate who gets notified of balance changes
    var delegate: AddressDelegate?
    
    /// returns trading pair constructed from Wallet.baseCurrency + cryptoCurrency
    var tradingPair: Currency.TradingPair {
        return Currency.tradingPair(cryptoCurrency: Currency.Crypto(rawValue: cryptoCurrency!)!, fiatCurrency: Wallet.baseCurrency)!
    }
    
    /// returns the oldest transaction
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

    /// returns the current exchange value according to set trading pair
    var currentExchangeValue: Double? {
        if let unitExchangeValue = TickerWatchlist.currentPrice(for: tradingPair) {
            return balance * unitExchangeValue
        } else {
            return nil
        }
    }
    
    // MARK: - Public Methods
    /// returns absolute return history since specified date, nil if date is today or in the future
    func absolutReturnHistory(since date: Date) -> [(date: Date, date: Double)]? {
        guard !date.isToday(), !date.isFuture() else {
            return nil
        }
        
        var returnHistory: [(Date, Double)] = []
        let txs = Array(transactions!) as! [Transaction]
        
        for (index, tx) in txs.enumerated() {
            if let absoluteReturnHistory = tx.absoluteReturnHistory(since: date) {
                if index == 0 {
                    for (date, absoluteReturn) in absoluteReturnHistory {
                        returnHistory.append((date, absoluteReturn))
                    }
                } else {
                    returnHistory = zip(returnHistory, absoluteReturnHistory).map() { ($0.0, $0.1 + $1.1) }
                }
            } else {
                return nil
            }
        }
        
        return returnHistory
    }
    
    /// returns exchange value on speicfied date, nil if date is today or in the future
    func exchangeValue(on date: Date) -> Double? {
        guard !date.isToday(), !date.isFuture() else {
            return nil
        }
        
        if let unitExchangeValue = TickerPrice.tickerPrice(for: tradingPair, on: date)?.value {
            return balance * unitExchangeValue
        } else {
            return nil
        }
    }
    
    /// fetches and saves balance if it has changed, notifies delegate
    func updateBalance(in context: NSManagedObjectContext) {
        BlockchainConnector.fetchBalance(for: self, completion: { result in
            switch result {
            case let .success(balance):
                if balance != self.balance {
                    do {
                        self.balance = balance
                        try context.save()
                        print("Saved updated balance for \(self.address!).")
                        self.delegate?.didUpdateBalance(for: self)
                    } catch {
                        print("Failed to save fetched balance: \(error)")
                    }
                }
            case let .failure(error):
                print("Failed to fetch balance: \(error)")
            }
        })
    }
    
    /// fetches and saves transaction history since last retrieved block, executes completion block if no error is thrown during retrieval and saving
    func updateTransactionHistory(in context: NSManagedObjectContext, completion: (() -> Void)?) {
        let timeframe: TransactionHistoryTimeframe
        
        if lastBlock == 0 {
            timeframe = .allTime
        } else {
            timeframe = .sinceBlock(Int(lastBlock))
        }
        
        BlockchainConnector.fetchTransactionHistory(for: self, type: .normal, timeframe: timeframe) { result in
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
                    } else {
                        print("Normal transaction history is already up-to-date.")
                    }
                    
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
                                } else {
                                    print("Contract transaction history is already up-to-date.")
                                }
                                
                                if let completion = completion {
                                    completion()
                                }
                            } catch {
                                print("Failed to save fetched contract transaction history: \(error)")
                            }
                        case let .failure(error):
                            print("Failed to fetch contract transaction history: \(error)")
                        }
                    })
                } catch {
                    print("Failed to save fetched normal transaction history: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch normal transaction history: \(error)")
            }
        }
    }
    
    /// asks tickerPrice to update price history for set trading pair starting from oldest transaction date encountered, passes completion block
    func updatePriceHistory(completion: (() -> Void)?) {
        if let firstTransactionDate = oldestTransaction?.date {
            TickerPrice.updatePriceHistory(for: tradingPair, since: firstTransactionDate as Date, completion: completion)
        }
    }

}

protocol AddressDelegate {
    func didUpdateBalance(for address: Address)
}
