//
//  MarketPrice.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum MarketPriceError: Error {
    case duplicate
}

class MarketPrice: NSManagedObject {
    
    // MARK: - Private Class Methods
    /// returns newest ticker price for specified trading pair
    private class func getNewestMarketPrice(for currencyPair: CurrencyPair) -> MarketPrice? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<MarketPrice> = MarketPrice.fetchRequest()
        request.predicate = NSPredicate(format: "currencyPair = %@", currencyPair.name)
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
    class func createMarketPrice(from priceInfo: TickerConnector.Price, in context: NSManagedObjectContext) throws -> MarketPrice {
        let request: NSFetchRequest<MarketPrice> = MarketPrice.fetchRequest()
        request.predicate = NSPredicate(format: "currencyPair = %@ AND date = %@", priceInfo.currencyPair.name, priceInfo.date as NSDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "MarketPrice.createMarketPrice -- Database Inconsistency")
                throw MarketPriceError.duplicate
            }
        } catch {
            throw error
        }
        
        let price = MarketPrice(context: context)
        price.date = priceInfo.date
        price.currencyPair = priceInfo.currencyPair.name
        price.value = priceInfo.value
        
        return price
    }
    
    /// returns exchange value for specified trading pair on specified date, nil if date is today or in the future
    class func getMarketPrice(for currencyPair: CurrencyPair, on date: Date) -> Double? {
        guard !date.isUTCToday, !date.isUTCFuture else {
            return nil
        }
    
        let startDate = date.UTCStart as NSDate
        let endDate = date.UTCEnd as NSDate
        
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<MarketPrice> = MarketPrice.fetchRequest()
        request.predicate = NSPredicate(format: "currencyPair = %@ AND date >= %@ AND date < %@", currencyPair.name, startDate, endDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "MarketPrice.getMarketPrice -- Database Inconsistency")
                return matches[0].value
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    /// fetches and saves price history for specified trading pair starting from specified date, executes completion block if no error is thrown during retrieval and saving
    class func updatePriceHistory(for currencyPair: CurrencyPair, since date: Date, completion: (() -> Void)?) {
        var startDate: Date!
        
        if MarketPrice.getMarketPrice(for: currencyPair, on: date) == nil {
            startDate = date.UTCStart
        } else if let newestExchangeValueDate = getNewestMarketPrice(for: currencyPair)?.date {
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: newestExchangeValueDate as Date)!.UTCStart
        }
        
        guard !startDate.isUTCToday, !startDate.isUTCFuture else {
            log.verbose("Price history for currencyPair '\(currencyPair)' is already up-to-date.")
            completion?()
            return
        }
        
        TickerConnector.fetchPriceHistory(for: currencyPair, since: startDate) { result in
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
                            _ = try MarketPrice.createMarketPrice(from: price, in: context)
                            newPriceCount = newPriceCount + 1
                        }
                    } catch {
                        switch error {
                        case MarketPriceError.duplicate:
                            duplicateCount = duplicateCount + 1
                        default:
                            log.error("Failed to create MarketPrice for currencyPair '\(price.currencyPair.name)': \(error)")
                        }
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        let multiplePrices = newPriceCount >= 2 || newPriceCount == 0
                        log.debug("Saved price history for currencyPair '\(currencyPair.name)' with \(newPriceCount) new price\(multiplePrices ? "s" : "") since \(Format.getDateFormatting(for: startDate)).")
                    }
                    
                    completion?()
                } catch {
                    log.error("Failed to save fetched price history for currencyPair '\(currencyPair.name)': \(error)")
                }
            case .failure(let error):
                log.error("Failed to fetch price history for currencyPair '\(currencyPair.name)': \(error)")
            }
        }
    }
    
}
