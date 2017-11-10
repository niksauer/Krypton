//
//  Transaction.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum TransactionError: Error {
    case duplicate
    case invalidPrototype
}

@objc enum TransactionType: Int {
    case all
    case investment
    case other
}

enum TransactionValueType {
    case fee
    case total
}

enum ProfitTimeframe {
    case allTime
    case sinceDate(Date)
}

class Transaction: NSManagedObject {
    
    // MARK: - Public Class Methods
    /// creates and returns transaction if non-existent in database, throws otherwise
    class func createTransaction(from prototype: TransactionPrototype, owner: Address, in context: NSManagedObjectContext) throws -> Transaction {
        guard prototype.from.count >= 1, prototype.to.count >= 1 else {
            throw TransactionError.invalidPrototype
        }
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        switch owner {
        case is Ethereum:
            guard let prototype = prototype as? EthereumTransactionPrototype else {
                throw TransactionError.invalidPrototype
            }
            
            request.predicate = NSPredicate(format: "identifier = %@ AND owner = %@ AND type = %@ ", prototype.identifier, owner, prototype.type.rawValue)
        default:
            request.predicate = NSPredicate(format: "identifier = %@ AND owner = %@", prototype.identifier, owner)
        }
    
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Transaction.createTransaction -- Database Inconsistency")
                throw TransactionError.duplicate
            }
        } catch {
            throw error
        }
        
        let transaction: Transaction
        
        switch owner {
        case is Ethereum:
            guard let prototype = prototype as? EthereumTransactionPrototype, prototype.from.count == 1, prototype.to.count == 1 else {
                throw TransactionError.invalidPrototype
            }
            
            let ethereumTransaction = EthereumTransaction(context: context)
            ethereumTransaction.type = prototype.type.rawValue
            ethereumTransaction.isError = prototype.isError
            
            transaction = ethereumTransaction
        case is Bitcoin:
            guard let prototype = prototype as? BitcoinTransactionPrototype else {
                throw TransactionError.invalidPrototype
            }
            
            let bitcoinTransaction = BitcoinTransaction(context: context)
            bitcoinTransaction.amountFromSender = NSDictionary(dictionary: prototype.amountFromSender)
            bitcoinTransaction.amountForReceiver = NSDictionary(dictionary: prototype.amountForReceiver)
            
            transaction = bitcoinTransaction
        default:
            transaction = Transaction(context: context)
        }
        
        transaction.identifier = prototype.identifier
        transaction.date = prototype.date
        transaction.totalAmount = prototype.totalAmount
        transaction.feeAmount = prototype.feeAmount
        transaction.block = Int32(prototype.block)
        transaction.to = prototype.to as NSObject
        transaction.from = prototype.from as NSObject
        transaction.isOutbound = prototype.isOutbound
        transaction.owner = owner
        
        return transaction
    }
    
    // MARK: - Public Properties
    var senders: [String] {
        return from as! [String]
    }
    
    var primarySender: String {
        return senders.contains(self.owner!.identifier!) ? self.owner!.identifier! : senders.first!
    }
    
    var receivers: [String] {
        return to as! [String]
    }
    
    var primaryReceiver: String {
        return receivers.contains(self.owner!.identifier!) ? self.owner!.identifier! : receivers.first!
    }
    
    /// returns exchange value as encountered on execution date according to owners trading pair
    var exchangeValue: Double? {
        return getExchangeValue(on: date! as Date, for: .total)
    }
    
    /// returns the current exchange value according to owners trading pair
    var currentExchangeValue: Double? {
        return getExchangeValue(on: Date(), for: .total)
    }
    
    var feeExchangeValue: Double? {
        return getExchangeValue(on: date! as Date, for: .fee)
    }
    
    var feeCurrentExchangeValue: Double? {
        return getExchangeValue(on: Date(), for: .fee)
    }
    
    var logDescription: String {
        return "\(self.identifier!), owner: \(self.owner!.logDescription)"
    }
    
    var hasUserExchangeValue: Bool {
        return userExchangeValue != -1
    }
    
    // MARK: - Public Methods
    /// replaces exchange value as encountered on execution date by user specified value, notifies owner's delegate if change occurred
    func setUserExchangeValue(value newValue: Double) throws {
        guard newValue != userExchangeValue else {
            return
        }
        
        do {
            userExchangeValue = newValue
            try AppDelegate.viewContext.save()
            log.debug("Updated user exchange value (\(newValue)) for transaction '\(self.logDescription)'.")
            self.owner!.delegate?.didUpdateUserExchangeValue(for: self)
        } catch {
            log.error("Failed to update user exchange value for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    /// updates isInvestment status as specified by user, notifies owner's delegate if change occurred
    func setIsInvestment(state newValue: Bool) throws {
        guard newValue != isInvestment else {
            return
        }
        
        do {
            isInvestment = newValue
            try AppDelegate.viewContext.save()
            log.debug("Updated isInvestment status (\(newValue)) for transaction '\(self.logDescription)'.")
            self.owner!.delegate?.didUpdateIsInvestmentStatus(for: self)
        } catch {
            log.error("Failed to update isInvestment status for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    func setIsUnread(state newValue: Bool) throws {
        guard newValue != isUnread else {
            return
        }
        
        do {
            isUnread = newValue
            try AppDelegate.viewContext.save()
            log.debug("Updated isUnread status (\(newValue)) for transaction '\(self.logDescription)'.")
        } catch {
            log.error("Failed to update isUnread status for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    func resetUserExchangeValue() throws {
        do {
            userExchangeValue = -1
            try AppDelegate.viewContext.save()
            log.debug("Reset user exchange value for transaction '\(self.logDescription)'.")
            self.owner!.delegate?.didUpdateUserExchangeValue(for: self)
        } catch {
            log.error("Failed to reset user exchange value for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    // MARK: Finance
    func getExchangeValue(on date: Date, for type: TransactionValueType) -> Double? {
        guard !date.isFuture else {
            return nil
        }
        
        if date.UTCStart == self.date?.UTCStart, hasUserExchangeValue {
            return userExchangeValue
        }
        
        guard let unitExchangeValue = owner?.tradingPair.getValue(on: date) else {
            log.warning("Failed to get exchange value for transaction '\(self.logDescription)'.")
            return nil
        }

        switch type {
        case .fee:
            return unitExchangeValue * feeAmount
        case .total:
            return unitExchangeValue * totalAmount
        }
    }

    /// returns the total absolute profit according to owners trading pair
    func getProfitStats(timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        let startDate: Date
        let txDate = self.date! as Date
        
        switch timeframe {
        case .allTime:
            startDate = txDate
        case .sinceDate(let date):
            guard !date.isToday, !date.isFuture else {
                return nil
            }
        
            if date < txDate {
                startDate = txDate
            } else {
                startDate = date
            }
        }
        
        guard let startValue = getExchangeValue(on: startDate, for: .total), let endValue = getExchangeValue(on: Date(), for: .total) else {
            return nil
        }
        
        if isOutbound {
            return (startValue * -1, endValue * -1)
        } else {
            return (startValue, endValue)
        }
    }
    
    /// returns absolute profit history since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }

        let sinceDate = date.UTCStart
        let txDate = (self.date! as Date).UTCStart
        
        var absoluteProfitHistory: [(Date, Double)] = []

        // fill response with 0s if requested date preceeds transaction
        // calculate start date of absolute return history -> either specified date or transaction start
        let startDate: Date
    
        if sinceDate < txDate {
            // calculate number of days between sinceDate and txDance, including txDate ??
            let daysUntilStart = Calendar.current.dateComponents([.day], from: sinceDate, to: txDate).day!
            
            for daysPassed in 0..<daysUntilStart {
                let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: sinceDate)!
                let absoluteProfit = 0.0
                absoluteProfitHistory.append((date, absoluteProfit))
            }
            
            startDate = Calendar.current.date(byAdding: .day, value: daysUntilStart, to: sinceDate)!
        } else {
            startDate = sinceDate
        }
        
        // get transaction value at start date
        guard let baseExchangeValue = getExchangeValue(on: startDate, for: .total) else {
            return nil
        }
        
        // calculate number of days between startDate and today, including today
        // calculate return history for that timeframe accordingly
        let daysMissing = Calendar.current.dateComponents([.day], from: startDate, to: Date().UTCStart).day!
        
        for daysPassed in 0...daysMissing {
            let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: startDate)!
            var absoluteProfit: Double

            if daysPassed == 0 {
                // return for startDate
                absoluteProfit = 0.0
            } else if let exchangeValue = getExchangeValue(on: date, for: .total) {
                // return for any day between startDate and today, including today
                absoluteProfit = exchangeValue - baseExchangeValue
            } else {
                // error retrieving tickerprice
                return nil
            }

            // outbound transaction = loss
            if isOutbound {
                absoluteProfit = absoluteProfit * -1
            }

            absoluteProfitHistory.append((date, absoluteProfit))
        }
        
        return absoluteProfitHistory
    }
    
}

class EthereumTransaction: Transaction {
    
}

class BitcoinTransaction: Transaction {
    
}
