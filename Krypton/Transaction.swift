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

enum TransactionType: Int {
    case all = 0, investment, other
}

enum ProfitTimeframe {
    case allTime
    case sinceDate(Date)
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
    /// checks if transaction is outbound, i.e. owner sent amount and has not received it
    var isOutbound: Bool {
        return from!.caseInsensitiveCompare(owner!.address!) == ComparisonResult.orderedSame
    }
    
    /// returns exchange value as encountered on execution date according to owners trading pair
    var exchangeValue: Double? {
        return getExchangeValue(on: date! as Date)
    }
    
    /// returns the current exchange value according to owners trading pair
    var currentExchangeValue: Double? {
        return getExchangeValue(on: Date())
    }
    
    // MARK: - Public Methods
    // MARK: Finance
    func getExchangeValue(on date: Date) -> Double? {
        guard !date.isFuture else {
            return nil
        }
        
        let unitExchangeValue: Double?
        
        if date.isToday {
            unitExchangeValue = TickerWatchlist.currentPrice(for: owner!.tradingPair)
        } else {
            unitExchangeValue = TickerPrice.tickerPrice(for: owner!.tradingPair, on: date)?.value
        }
        
        guard unitExchangeValue != nil else {
            return nil
        }
        
        return unitExchangeValue! * amount
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
        
        guard let startValue = getExchangeValue(on: startDate), let endValue = currentExchangeValue else {
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
        guard let unitExchangeValue = TickerPrice.tickerPrice(for: owner!.tradingPair, on: startDate)?.value else {
            return nil
        }
        
        let baseExchangeValue = unitExchangeValue * amount
        
        // calculate number of days between startDate and today, including today
        // calculate return history for that timeframe accordingly
        let daysMissing = Calendar.current.dateComponents([.day], from: startDate, to: Date().UTCStart).day!
        
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
    
    // MARK: Setters
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


