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
    case invalid
}

protocol AddressDelegate {
    func didUpdateTransactionHistory(for address: Address)
    func didUpdateBalance(for address: Address)
    func didUpdateAlias(for address: Address)
    func didUpdateBaseCurrency(for address: Address)
    func didUpdateUserExchangeValue(for transaction: Transaction)
    func didUpdateIsInvestmentStatus(for transaction: Transaction)
}

class Address: NSManagedObject {
    
    // MARK: - Public Class Methods
    /// creates and returns address if non-existent in database, throws otherwise
    class func createAddress(_ addressString: String, alias: String?, blockchain: Blockchain, baseCurrency: Currency, in context: NSManagedObjectContext) throws -> Address {
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@", addressString)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Address.createAddress -- Database Inconsistency")
                throw AddressError.duplicate
            }
        } catch {
            throw error
        }
        
        let address: Address
        
        switch blockchain {
        case .ETH:
            address = Ethereum(context: context)
        case .XBT:
            address = Bitcoin(context: context)
        }
    
        address.identifier = addressString
        
        guard address.isValidAddress() else {
            context.delete(address)
            throw AddressError.invalid
        }
        
        address.alias = alias
        address.baseCurrencyCode = baseCurrency.code
        
        return address
    }
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in balance, transaction history and all associated transactions' userExchangeValue, isInvestment properties
    var delegate: AddressDelegate?
    
    var blockchain: Blockchain {
        get {
            return Blockchain(rawValue: blockchainRaw!)!
        }
    }
    
    private(set) public var baseCurrency: Currency {
        get {
            return CurrencyManager.getCurrency(from: baseCurrencyCode!)!
        }
        set {
            baseCurrencyCode = newValue.code
        }
    }
    
    /// returns trading pair constructed from owner's baseCurrency + address' cryptoCurrency
    var tradingPair: TradingPair {
        return TradingPair.getTradingPair(a: blockchain, b: baseCurrency)!
    }
    
    /// returns all transaction associated with address
    var storedTransactions: [Transaction] {
        return Array(transactions!) as! [Transaction]
    }
    
    // MARK: - Private Methods
    private func getTransactions(of type: TransactionType) -> [Transaction] {
        switch type {
        case .investment:
            return storedTransactions.filter { $0.isInvestment }
        case .other:
            return storedTransactions.filter { !$0.isInvestment }
        case .all:
            return storedTransactions
        }
    }
    
    // MARK: - Public Methods
    /// returns the oldest transaction associated with address
    func getOldestTransaction() -> Transaction? {
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
    
    func setAlias(_ alias: String) throws {
        guard self.alias != alias else {
            return
        }
        
        do {
            self.alias = alias
            try AppDelegate.viewContext.save()
            print("Saved updated alias for address: \(identifier!)")
            delegate?.didUpdateAlias(for: self)
        } catch {
            throw error
        }
    }
    
    func setBaseCurrency(_ currency: Currency) throws {
        guard self.baseCurrency.code != currency.code else {
            return
        }
        
        do {
            self.baseCurrencyCode = currency.code
            try AppDelegate.viewContext.save()
            print("Saved updated base currency for address \(identifier!).")
            delegate?.didUpdateBaseCurrency(for: self)
        } catch {
            throw error
        }
    }
    
    // MARK: Management
    func update(completion: (() -> Void)?) {
        self.updateTransactionHistory {
            self.updatePriceHistory {
                self.updateBalance {
                    completion?()
                }
            }
        }
    }
    
    /// fetches and saves balance if it has changed, notifies delegate
    func updateBalance(completion: (() -> Void)?) {
        BlockchainConnector.fetchBalance(for: self) { result in
            switch result {
            case .success(let balance):
                guard balance != self.balance else {
                    print("Balance for \(self.identifier!) is already up-to-date.")
                    completion?()
                    return
                }
                
                do {
                    self.balance = balance
                    try AppDelegate.viewContext.save()
                    print("Saved updated balance for \(self.identifier!).")
                    self.delegate?.didUpdateBalance(for: self)
                    completion?()
                } catch {
                    print("Failed to save fetched balance for \(self.identifier!): \(error)")
                }
            case .failure(let error):
                print("Failed to fetch balance for \(self.identifier!): \(error)")
            }
        }
    }
    
    /// fetches and saves transaction history since last retrieved block, executes completion block if no error is thrown during retrieval and saving
    func updateTransactionHistory(completion: (() -> Void)?) {
        preconditionFailure("This method must be overridden")
    }
    
    /// asks tickerPrice to update price history for set trading pair starting from oldest transaction date encountered, passes completion block to retrieval
    func updatePriceHistory(completion: (() -> Void)?) {
        if let firstTransaction = getOldestTransaction() {
            TickerPrice.updatePriceHistory(for: tradingPair, since: firstTransaction.date! as Date, completion: completion)
        } else {
            completion?()
        }
    }
    
    // MARK: Finance
    /// returns balance for specified transaction type on specified date
    func getBalance(for type: TransactionType, on date: Date) -> Double? {
        guard storedTransactions.count > 0 else {
            return 0.0
        }
        
        let transactions = getTransactions(of: type).filter { $0.date! <= date }
        var balance = 0.0
    
        for transaction in transactions {
            if transaction.isOutbound {
                balance = balance - transaction.totalAmount
            } else {
                balance = balance + transaction.totalAmount
            }
        }
        
        return balance
    }
    
    /// returns exchange value on speicfied date, nil if date is in the future
    func getExchangeValue(for type: TransactionType, on date: Date) -> (balance: Double, value: Double)? {
        guard !date.isFuture, let balance = getBalance(for: type, on: date) else {
            return nil
        }
        
        let unitExchangeValue: Double?
        
        if date.isToday {
            unitExchangeValue = TickerWatchlist.getCurrentPrice(for: tradingPair)
        } else {
            unitExchangeValue = TickerPrice.getTickerPrice(for: tradingPair, on: date)?.value
        }
        
        guard unitExchangeValue != nil else {
            return nil
        }
        
        return (balance, unitExchangeValue! * balance)
    }
    
    /// returns total value invested in address
    func getProfitStats(for type: TransactionType, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        let transactions = getTransactions(of: type)
        
        for transaction in transactions {
            if let profitStats = transaction.getProfitStats(timeframe: timeframe) {
                startValue = startValue + profitStats.startValue
                endValue = endValue + profitStats.endValue
            } else {
                return nil
            }
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute return history since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(for type: TransactionType, since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture, storedTransactions.count > 0 else {
            return nil
        }
        
        let transactions = getTransactions(of: type)
        var profitHistory: [(Date, Double)] = []
        
        for transaction in transactions {
            guard let absoluteReturnHistory = transaction.getAbsoluteProfitHistory(since: date) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteReturnHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
    // MARK: Cryptography
    func isValidAddress() -> Bool {
        preconditionFailure("This method must be overridden")
    }
    
}

class Bitcoin: Address {

    // MARK: - Initializers
    override func awakeFromInsert() {
        super.awakeFromInsert()
        blockchainRaw = Blockchain.XBT.rawValue
    }
    
}
