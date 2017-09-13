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

    // MARK: - Private Properties
    /// returns the oldest transaction associated with address
    private var oldestTransaction: Transaction? {
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
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in balance, transaction history and all associated transactions' userExchangeValue, isInvestment properties
    var delegate: AddressDelegate?
    
    /// returns all transaction associated with address
    var storedTransactions: [Transaction] {
        return Array(transactions!) as! [Transaction]
    }
    
    /// returns trading pair constructed from owner's baseCurrency + address' cryptoCurrency
    var tradingPair: Currency.TradingPair {
        return Currency.tradingPair(cryptoCurrency: Currency.Crypto(rawValue: cryptoCurrency!)!, fiatCurrency: Currency.Fiat(rawValue: portfolio!.baseCurrency!)!)!
    }

    /// returns the current exchange value according to set trading pair
    var currentExchangeValue: Double? {
        if let unitExchangeValue = TickerWatchlist.currentPrice(for: tradingPair) {
            return balance * unitExchangeValue
        } else {
            return nil
        }
    }
    
    /// returns the absolute profit generated from all transactions according to set trading pair
    var absoluteProfit: Double? {
        if currentExchangeValue != nil, investmentValue != nil {
            return currentExchangeValue! - investmentValue!
        } else {
            return nil
        }
    }
    
    /// returns total value invested in address
    var investmentValue: Double? {
        var investmentValue = 0.0
        for transaction in storedTransactions {
            if let txInvestmentValue = transaction.investmentValue {
                investmentValue = investmentValue + txInvestmentValue
            } else {
                return nil
            }
        }
        return investmentValue
    }
    
    // MARK: - Public Methods
    /// returns the absolute profit generated from all transactions since specified date according to set trading pair
    func absoluteProfit(since date: Date) -> Double? {
        guard storedTransactions.count > 0 else {
            return 0.0
        }
        
        if let oldestTransactionDate = oldestTransaction?.date, let absoluteProfitHistory = absoluteProfitHistory(since: oldestTransactionDate as Date), let absoluteProfit = absoluteProfitHistory.last?.profit {
            return absoluteProfit
        } else {
            return nil
        }
    }
    
    /// returns absolute return history since specified date, nil if date is today or in the future
    func absoluteProfitHistory(since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for (index, tx) in storedTransactions.enumerated() {
            if let absoluteReturnHistory = tx.absoluteProfitHistory(since: date) {
                if index == 0 {
                    for (date, absoluteReturn) in absoluteReturnHistory {
                        profitHistory.append((date, absoluteReturn))
                    }
                } else {
                    profitHistory = zip(profitHistory, absoluteReturnHistory).map() { ($0.0, $0.1 + $1.1) }
                }
            } else {
                return nil
            }
        }
        
        return profitHistory
    }
    
    /// returns exchange value on speicfied date, nil if date is today or in the future
    func exchangeValue(on date: Date) -> Double? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        if let unitExchangeValue = TickerPrice.tickerPrice(for: tradingPair, on: date)?.value {
            return balance * unitExchangeValue
        } else {
            return nil
        }
    }
    
    /// fetches and saves balance if it has changed, notifies delegate
    func updateBalance() {
        BlockchainConnector.fetchBalance(for: self, completion: { result in
            switch result {
            case let .success(balance):
                if balance != self.balance {
                    do {
                        self.balance = balance
                        try AppDelegate.viewContext.save()
                        print("Saved updated balance for \(self.address!).")
                        self.delegate?.didUpdateBalance(for: self)
                    } catch {
                        print("Failed to save fetched balance: \(error)")
                    }
                } else {
                    print("Balance for \(self.address!) is already up-to-date.")
                }
            case let .failure(error):
                print("Failed to fetch balance: \(error)")
            }
        })
    }
    
    /// fetches and saves transaction history since last retrieved block, executes completion block if no error is thrown during retrieval and saving
    func updateTransactionHistory(completion: (() -> Void)?) {
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
                                
                                self.delegate?.didUpdateTransactionHistory(for: self)
                                
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

// MARK: - Address Delegate Protocol
protocol AddressDelegate {
    func didUpdateTransactionHistory(for address: Address)
    func didUpdateBalance(for address: Address)
    func didUpdateUserExchangeValue(for transaction: Transaction)
    func didUpdateIsInvestmentStatus(for transaction: Transaction)
}
