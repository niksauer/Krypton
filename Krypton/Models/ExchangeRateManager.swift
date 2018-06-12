//
//  ExchangeRateManager.swift
//  Krypton
//
//  Created by Niklas Sauer on 05.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

struct ExchangeRateManager {
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext
    private let tickerDaemon: TickerDaemon
    private let exchange: Exchange
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, tickerDaemon: TickerDaemon, exchange: Exchange) {
        self.context = context
        self.tickerDaemon = tickerDaemon
        self.exchange = exchange
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
        guard !date.isUTCFuture else {
            return nil
        }
        
        guard !date.isUTCToday else {
            return tickerDaemon.getCurrentExchangeRate(for: currencyPair)
        }
        
        let startDate = date.UTCStart
        let endDate = date.UTCEnd
        
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        request.predicate = NSPredicate(format: "base = %@ AND quote = %@ AND date >= %@ AND date < %@", currencyPair.base.code, currencyPair.quote.code, startDate as NSDate, endDate as NSDate)
        
        do {
            let matches = try context.fetch(request)
            
            if matches.count > 0 {
                assert(matches.count >= 1, "ExchangeRateManager.getExchangeRate(for:on:) -- Database Inconsistency")
                return matches[0].value
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    /// fetches and saves exchangeRate history for specified trading pair starting from specified date, executes completion block if no error is thrown during retrieval and saving
    func updateExchangeRateHistory(for currencyPair: CurrencyPair, since date: Date, completion: ((Error?) -> Void)?) {
        let startDate: Date
        
        if getExchangeRate(for: currencyPair, on: date) == nil {
            startDate = date.UTCStart
        } else if let newestExchangeRate = getNewestExchangeRate(for: currencyPair) {
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: newestExchangeRate.date!)!.UTCStart
        } else {
            startDate = date.UTCStart
        }
        
        guard !startDate.isUTCToday, !startDate.isUTCFuture else {
            log.verbose("Exchange rate history for currency pair '\(currencyPair.name)' is already up-to-date.")
            completion?(nil)
            return
        }
        
        exchange.fetchExchangeRateHistory(for: currencyPair, since: startDate) { history, error in
            guard let history = history else {
                log.error("Failed to fetch exchange rate history for currency pair '\(currencyPair.name)': \(error!)")
                completion?(error!)
                return
            }
            
            var count = 0
            
            for exchangeRate in history {
                do {
                    // leave out result for today
                    guard !exchangeRate.date.isUTCToday else {
                        continue
                    }
                    
                    _ = try ExchangeRate.createExchangeRate(from: exchangeRate, in: self.context)
                    count = count + 1
                } catch {
                    log.error("Failed to create exchange rate for currency pair '\(currencyPair.name)': \(error)")
                }
            }
            
            do {
                try self.context.save()
                let multiple = count >= 2 || count == 0
                log.debug("Saved exchange rate history for currency pair '\(currencyPair.name)' with \(count) new value\(multiple ? "s" : "") since \(startDate)).")
                completion?(nil)
            } catch {
                log.error("Failed to save fetched exchange rate history for currency pair '\(currencyPair.name)': \(error)")
                completion?(error)
            }
        }
    }
    
}
