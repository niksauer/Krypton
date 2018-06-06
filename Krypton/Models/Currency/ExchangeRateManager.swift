//
//  ExchangeRateManager.swift
//  Krypton
//
//  Created by Niklas Sauer on 05.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

class ExchangeRateManager {
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext
    private let tickerDaemon: TickerDaemon
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, tickerDaemon: TickerDaemon) {
        self.context = context
        self.tickerDaemon = tickerDaemon
    }
    
    // MARK: - Private Methods
    /// returns newest ticker exchangeRate for specified trading pair
    private func getNewestExchangeRate(for currencyPair: CurrencyPair) -> ExchangeRate? {
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        request.predicate = NSPredicate(format: "base = %@ AND quote = %@", currencyPair.base.code, currencyPair.quote.code)
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
    
    // MARK: - Public Methods
    /// returns exchange value for specified trading pair on specified date, nil if date is today or in the future
    func getExchangeRate(for currencyPair: CurrencyPair, on date: Date) -> Double? {
        guard !date.isUTCToday else {
            if !date.isUTCFuture {
                return tickerDaemon.getCurrentExchangeRate(for: currencyPair)
            } else {
                return nil
            }
        }
        
        let startDate = date.UTCStart as NSDate
        let endDate = date.UTCEnd as NSDate
        
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        request.predicate = NSPredicate(format: "base = %@ AND quote = %@ AND date >= %@ AND date < %@", currencyPair.base.code, currencyPair.quote.code, startDate, endDate)
        
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
    func updateExchangeRateHistory(for currencyPair: CurrencyPair, since date: Date, completion: (() -> Void)?) {
        var startDate: Date!
        
        if getExchangeRate(for: currencyPair, on: date) == nil {
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
                var count = 0
                var duplicateCount = 0
                
                for exchangeRate in history {
                    do {
                        let date = exchangeRate.date as Date
                        
                        // leave out result for today
                        if !date.isUTCToday {
                            _ = try ExchangeRate.createExchangeRate(from: exchangeRate, in: self.context)
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
                    if self.context.hasChanges {
                        try self.context.save()
                        let multiple = count >= 2 || count == 0
                        log.debug("Saved exchange rate history for currency pair '\(currencyPair.name)' with \(count) new value\(multiple ? "s" : "") since \(startDate)).")
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
