//
//  TickerPrice.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum TickerPriceError: Error {
    case duplicate
}

class TickerPrice: NSManagedObject {
    
    // MARK: - Private Class Methods
    /// returns newest ticker price for specified trading pair
    private class func getNewestTickerPrice(for tradingPair: TradingPair) -> TickerPrice? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "tradingPairRaw = %@", tradingPair.rawValue)
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
    /// creates and returns ticker price if non-existent in database, throws otherwise
    class func createTickerPrice(from priceInfo: TickerConnector.Price, in context: NSManagedObjectContext) throws -> TickerPrice {
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "tradingPairRaw = %@ AND date = %@", priceInfo.tradingPair.rawValue, priceInfo.date as NSDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "TickerPrice.createTickerPrice -- Database Inconsistency")
                throw TickerPriceError.duplicate
            }
        } catch {
            throw error
        }
        
        let tickerPrice = TickerPrice(context: context)
        tickerPrice.date = priceInfo.date
        tickerPrice.tradingPairRaw = priceInfo.tradingPair.rawValue
        tickerPrice.value = priceInfo.value
        
        return tickerPrice
    }
    
    /// returns exchange value for specified trading pair on specified date, nil if date is today or in the future
    class func getTickerPrice(for tradingPair: TradingPair, on date: Date) -> TickerPrice? {
        guard !date.isUTCToday, !date.isUTCFuture else {
            return nil
        }
    
        let startDate = date.UTCStart as NSDate
        let endDate = date.UTCEnd as NSDate
        
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "tradingPairRaw = %@ AND date >= %@ AND date < %@", tradingPair.rawValue, startDate, endDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "TickerPrice.getTickerPrice -- Database Inconsistency")
                return matches[0]
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    /// fetches and saves price history for specified trading pair starting from specified date, executes completion block if no error is thrown during retrieval and saving
    class func updatePriceHistory(for tradingPair: TradingPair, since date: Date, completion: (() -> Void)?) {
        var startDate: Date!
        
        if TickerPrice.getTickerPrice(for: tradingPair, on: date) == nil {
            startDate = date.UTCStart
        } else if let newestExchangeValueDate = getNewestTickerPrice(for: tradingPair)?.date {
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: newestExchangeValueDate as Date)!.UTCStart
        }
        
        guard !startDate.isUTCToday, !startDate.isUTCFuture else {
            log.verbose("Price history for tradingPair '\(tradingPair)' is already up-to-date.")
            completion?()
            return
        }
        
        TickerConnector.fetchPriceHistory(for: tradingPair, since: startDate) { result in
            switch result {
            case let .success(priceHistory):
                let context = AppDelegate.viewContext
                var newPriceCount = 0
                var duplicateCount = 0
                
                for price in priceHistory {
                    do {
                        let date = price.date as Date
            
                        // leave out result for today
                        if !date.isUTCToday {
                            _ = try TickerPrice.createTickerPrice(from: price, in: context)
                            newPriceCount = newPriceCount + 1
                        }
                    } catch {
                        switch error {
                        case TickerPriceError.duplicate:
                            duplicateCount = duplicateCount + 1
                        default:
                            log.error("Failed to create tickerPrice for tradingPair '\(price.tradingPair.rawValue)': \(error)")
                        }
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        let multiplePrices = newPriceCount >= 2 || newPriceCount == 0
                        log.debug("Saved price history for tradingPair '\(tradingPair.rawValue)' with \(newPriceCount) new price\(multiplePrices ? "s" : "") since \(Format.getDateFormatting(for: startDate)).")
                    }
                    
                    completion?()
                } catch {
                    log.error("Failed to save fetched price history for tradingPair '\(tradingPair.rawValue)': \(error)")
                }
            case .failure(let error):
                log.error("Failed to fetch price history for tradingPair '\(tradingPair.rawValue)': \(error)")
            }
        }
    }
    
}
