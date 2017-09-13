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
    
    // MARK: - Public Class Methods
    /// creates and returns transaction if non-existent in database, throws otherwise
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
        transaction.amount = txInfo.amount
        transaction.type = txInfo.type.rawValue
        transaction.to = txInfo.to
        transaction.from = txInfo.from
        transaction.identifier = txInfo.identifier
        transaction.block = txInfo.block
        
        return transaction
    }
    
    // MARK: - Public Properties
    /// returns exchange value as encountered on execution date according to owners trading pair
    var exchangeValue: Double? {
        if let unitExchangeValue = TickerPrice.tickerPrice(for: self.owner!.tradingPair, on: date! as Date)?.value {
            return unitExchangeValue * amount
        } else {
            return nil
        }
    }
    
    /// returns the current exchange value according to owners trading pair
    var currentExchangeValue: Double? {
        if let unitExchangeValue = TickerWatchlist.currentPrice(for: self.owner!.tradingPair) {
            return unitExchangeValue * amount
        } else {
            return nil
        }
    }
    
    /// returns the total absolute profit according to owners trading pair
    var absoluteProfit: Double? {
        if currentExchangeValue != nil, exchangeValue != nil {
            return currentExchangeValue! - exchangeValue!
        } else {
            return nil
        }
    }
    
    /// returns the value of transaction when regarded as investment, must be specified as such, returns 0 otherwise
    /// will use userExchangeValue if specified
    /// outgoing -> investment has been realized = negative
    /// incoming -> investment has been made = positive
    var investmentValue: Double? {
        guard isInvestment else {
            return 0.0
        }
        
        var investmentValue: Double?
        
        if userExchangeValue != -1 {
            investmentValue = userExchangeValue
        } else {
            investmentValue = exchangeValue
        }
        
        guard investmentValue != nil else {
            return nil
        }
        
        if isOutbound {
            return investmentValue! * -1
        } else {
            return investmentValue!
        }
    }
    
    /// checks if transaction is outbound, i.e. owner sent amount and has not received it
    var isOutbound: Bool {
        return from!.caseInsensitiveCompare(owner!.address!) == ComparisonResult.orderedSame
    }
    
    // MARK: - Public Methods
    /// returns absolute profit history since specified date, nil if date is today or in the future
    func absoluteProfitHistory(since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isUTCToday, !date.isUTCFuture else {
            return nil
        }

        var absoluteProfitHistory: [(Date, Double)] = []

        // fill response with 0s if requested date preceeds transaction
        // calculate start date of absolute return history -> either specified date or transaction start
        let startDate: Date
        
        if date < self.date! as Date {
            let daysUntilStart = Calendar.current.dateComponents([.day], from: date, to: self.date! as Date).day!
            
            for daysPassed in 0..<daysUntilStart {
                let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: date)!
                let absoluteProfit = 0.0
                absoluteProfitHistory.append((date, absoluteProfit))
            }
            
            startDate = Calendar.current.date(byAdding: .day, value: daysUntilStart, to: date)!
        } else {
            startDate = date
        }
        
        // get transaction value at start date
        guard let unitExchangeValue = TickerPrice.tickerPrice(for: owner!.tradingPair, on: startDate)?.value else {
            return nil
        }
        
        let baseExchangeValue = unitExchangeValue * amount
        
        // calculate number of days between startDate and today, including today 
        // calculate return history for that timeframe accordingly
        let daysMissing = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day!
        
        for daysPassed in 0...daysMissing {
            let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: startDate)!
            var absoluteProfit: Double
            
            if daysPassed == 0 {
                // return for startDate
                absoluteProfit = 0.0
            } else if date.isUTCToday, currentExchangeValue != nil {
                // return for today
                absoluteProfit = currentExchangeValue! - baseExchangeValue
            } else if let unitExchangeValue = TickerPrice.tickerPrice(for: owner!.tradingPair, on: date)?.value {
                // return for any other day between startDate and today
                absoluteProfit = (unitExchangeValue * amount) - baseExchangeValue
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
    
    /// replaces exchange value as encountered on execution date by user specified value, notifies owner's delegate if change occurred
    func setUserExchangeValue(value newValue: Double) {
        guard newValue != userExchangeValue else {
            return
        }
        
        do {
            userExchangeValue = newValue
            try AppDelegate.viewContext.save()
            print("Saved updated user exchange value.")
            self.owner!.delegate?.didUpdateUserExchangeValue(for: self)
        } catch {
            print("Failed to save updated user exchange value.")
        }
    }
    
    /// updates isInvestment status as specified by user, notifies owner's delegate if change occurred
    func setIsInvestment(state newValue: Bool) {
        guard newValue != isInvestment else {
            return
        }
        
        do {
            isInvestment = newValue
            try AppDelegate.viewContext.save()
            print("Saved updated investment status.")
            self.owner!.delegate?.didUpdateIsInvestmentStatus(for: self)
        } catch {
            print("Failed to save updated investment status.")
        }
    }
    
}

