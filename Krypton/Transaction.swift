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
}

class Transaction: NSManagedObject {
    
    // MARK: - Class Methods
    /// creates and returns a transaction if non-existent in database, throws otherwise
    class func createTransaction(from txInfo: EtherscanAPI.Transaction, in context: NSManagedObjectContext) throws -> Transaction {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@ AND type = %@", txInfo.identifier, txInfo.type.rawValue)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Transaction.createTransaction -- Database Inconsistency")
                throw TransactionError.duplicate
            }
        } catch {
            throw error
        }
        
        let transaction = Transaction(context: context)
        transaction.date = txInfo.date
        transaction.value = txInfo.value
        transaction.type = txInfo.type.rawValue
        transaction.to = txInfo.to
        transaction.from = txInfo.from
        transaction.identifier = txInfo.identifier
        transaction.block = txInfo.block
        
        return transaction
    }
    
    // MARK: - Public Properties
    /// returns exchange value as encountered on execution date
    var exchangeValue: Double? {
        if let unitExchangeValue = TickerPrice.tickerPrice(for: self.owner!.tradingPair, on: date! as Date)?.value {
            return unitExchangeValue * value
        } else {
            return nil
        }
    }
    
    /// returns exchange value according to today's current price
    var currentExchangeValue: Double? {
        if let unitExchangeValue = TickerWatchlist.currentPrice(for: self.owner!.tradingPair) {
            return unitExchangeValue * value
        } else {
            return nil
        }
    }
    
    // MARK: - Public Methods
    func absoluteReturnHistory(since date: Date) -> [(date: Date, value: Double)]? {
        guard !date.isToday(), !date.isFuture() else {
            return nil
        }

        var returnHistory: [(Date, Double)] = []

        // fill response with 0s if requested date preceeds transaction
        // calculate start date of absolute return history -> either specified date or transaction start
        let startDate: Date
        
        if date < self.date! as Date {
            let daysUntilStart = Calendar.current.dateComponents([.day], from: date, to: self.date! as Date).day!
            
            for daysPassed in 0..<daysUntilStart {
                let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: date)!
                let absolutePerformance = 0.0
                returnHistory.append((date, absolutePerformance))
            }
            
            startDate = Calendar.current.date(byAdding: .day, value: daysUntilStart, to: date)!
        } else {
            startDate = date
        }
        
        guard let unitExchangeValue = TickerPrice.tickerPrice(for: owner!.tradingPair, on: startDate)?.value, let currentExchangeValue = currentExchangeValue else {
            return nil
        }
        
        // get transaction value at start date
        let baseExchangeValue = unitExchangeValue * value
        
        // calculate number of days for which return history must be aggregated
        let daysMissing = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day!
        
        for daysPassed in 0..<daysMissing {
            let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: startDate)!
            let unitExchangeValue = TickerPrice.tickerPrice(for: owner!.tradingPair, on: date)!.value
            let absolutePerformance = (unitExchangeValue * value) - baseExchangeValue
            returnHistory.append((date, absolutePerformance))
        }
        
        // todays absolute return
        returnHistory.append((Date(), currentExchangeValue - baseExchangeValue))
        
        return returnHistory
    }
    
    /// replaces exchange value as encountered on execution date by user defined value
    func setUserExchangeValue(_ newValue: Double, in context: NSManagedObjectContext) {
        if newValue != userExchangeValue {
            userExchangeValue = newValue
            
            do {
                try context.save()
                print("Saved updated user exchange value.")
            } catch {
                print("Failed to save updated user exchange value.")
            }
        }
    }
    
}

