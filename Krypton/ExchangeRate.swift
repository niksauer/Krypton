//
//  ExchangeRate.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum ExchangeRateError: Error {
    case duplicate
}

class ExchangeRate: NSManagedObject {
    
    // MARK: - Private Class Methods
    /// returns newest ticker exchangeRate for specified trading pair
    private class func getNewestExchangeRate(for currencyPair: CurrencyPair) -> ExchangeRate? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        request.predicate = NSPredicate(format: "base = %@ AND quote = %@ AND date = %@", currencyPair.base.code, currencyPair.quote.code)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
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
    
    // MARK: - Public Class Methods
    /// creates and returns ticker exchangeRate if non-existent in database, throws otherwise
    class func createExchangeRate(from prototype: TickerConnector.ExchangeRate, in context: NSManagedObjectContext) throws -> ExchangeRate {
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        request.predicate = NSPredicate(format: "base = %@ AND quote = %@ AND date = %@", prototype.currencyPair.base.code, prototype.currencyPair.quote.code, prototype.date as NSDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "ExchangeRate.createExchangeRate -- Database Inconsistency")
                throw ExchangeRateError.duplicate
            }
        } catch {
            throw error
        }
        
        let exchangeRate = ExchangeRate(context: context)
        
        exchangeRate.date = prototype.date
        exchangeRate.base = prototype.currencyPair.base.code
        exchangeRate.quote = prototype.currencyPair.quote.code
        exchangeRate.value = prototype.value
        
        return exchangeRate
    }
    
    /// returns exchange value for specified trading pair on specified date, nil if date is today or in the future
    class func getExchangeRate(for currencyPair: CurrencyPair, on date: Date) -> Double? {
        guard !date.isUTCToday, !date.isUTCFuture else {
            return nil
        }
    
        let startDate = date.UTCStart as NSDate
        let endDate = date.UTCEnd as NSDate
        
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        request.predicate = NSPredicate(format: "base = %@ AND quote = %@ AND date = %@ AND date >= %@ AND date < %@", currencyPair.base.code, currencyPair.quote.code, startDate, endDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "ExchangeRate.getExchangeRate -- Database Inconsistency")
                return matches[0].value
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    /// fetches and saves exchangeRate history for specified trading pair starting from specified date, executes completion block if no error is thrown during retrieval and saving
    class func updateExchangeRateHistory(for currencyPair: CurrencyPair, since date: Date, completion: (() -> Void)?) {
        var startDate: Date!
        
        if ExchangeRate.getExchangeRate(for: currencyPair, on: date) == nil {
            startDate = date.UTCStart
        } else if let newestExchangeRate = getNewestExchangeRate(for: currencyPair) {
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: newestExchangeRate.date!)!.UTCStart
        }
        
        guard !startDate.isUTCToday, !startDate.isUTCFuture else {
            log.verbose("Exchange rate history for currency pair '\(currencyPair.name)' is already up-to-date.")
            completion?()
            return
        }
        
        TickerConnector.fetchExchangeRateHistory(for: currencyPair, since: startDate) { result in
            switch result {
            case let .success(history):
                let context = AppDelegate.viewContext
                var count = 0
                var duplicateCount = 0
                
                for exchangeRate in history {
                    do {
                        let date = exchangeRate.date as Date
            
                        // leave out result for today
                        if !date.isUTCToday {
                            _ = try ExchangeRate.createExchangeRate(from: exchangeRate, in: context)
                            count = count + 1
                        }
                    } catch {
                        switch error {
                        case ExchangeRateError.duplicate:
                            duplicateCount = duplicateCount + 1
                        default:
                            log.error("Failed to create exchange rate for currency pair '\(currencyPair.name)': \(error)")
                        }
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        let multiple = count >= 2 || count == 0
                        log.debug("Saved exchange rate history for currency pair '\(currencyPair.name)' with \(count) new value\(multiple ? "s" : "") since \(Format.getDateFormatting(for: startDate)).")
                    }
                    
                    completion?()
                } catch {
                    log.error("Failed to save fetched exchange rate history for currency pair '\(currencyPair.name)': \(error)")
                }
            case .failure(let error):
                log.error("Failed to fetch exchange rate history for currency pair '\(currencyPair.name)': \(error)")
            }
        }
    }
    
}
