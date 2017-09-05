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
    private class func newestTickerPrice(for tradingPair: Currency.TradingPair) -> TickerPrice? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "tradingPair = %@", tradingPair.rawValue)
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
    class func createTickerPrice(from priceInfo: KrakenAPI.Price, in context: NSManagedObjectContext) throws -> TickerPrice {
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "date = %@", priceInfo.date)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "TickerPrice.createTickerPrice -- Database Inconsistency")
                throw TickerPriceError.duplicate
            }
        } catch {
            throw error
        }
        
        let price = TickerPrice(context: context)
        price.date = priceInfo.date
        price.tradingPair = priceInfo.tradingPair.rawValue
        price.value = priceInfo.value
        
        return price
    }
    
    /// returns exchange value for specified trading pair on specified date, nil if date is today or in the future
    class func tickerPrice(for tradingPair: Currency.TradingPair, on date: Date) -> TickerPrice? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        let timezone = TimeZone(abbreviation: "UTC")!
        let startDate = Date.start(of: date, in: timezone)
        let endDate = Date.end(of: date, in: timezone)
        
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "tradingPair = %@ AND date >= %@ AND date < %@", tradingPair.rawValue, startDate as NSDate, endDate as NSDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Address.addAddress -- Database Inconsistency")
                return matches[0]
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    /// fetches and saves price history for specified trading pair starting from specified date, executes completion block if no error is thrown during retrieval and saving
    class func updatePriceHistory(for tradingPair: Currency.TradingPair, since date: Date, completion: (() -> Void)?) {
        var startDate: Date? = nil
        let timezone = TimeZone(abbreviation: "UTC")!
        
        if TickerPrice.tickerPrice(for: tradingPair, on: date) == nil {
            startDate = Date.start(of: date, in: timezone)
        } else if let newestExchangeValueDate = newestTickerPrice(for: tradingPair)?.date {
            startDate = Date.start(of: Calendar.current.date(byAdding: .day, value: 1, to: newestExchangeValueDate as Date)!, in: timezone)
        } else {
            // database lookup error
        }
        
        guard let downloadStartDate = startDate, !downloadStartDate.isToday, !downloadStartDate.isFuture else {
            if let completion = completion {
                completion()
            }
            
            print("Price history for trading pair \(tradingPair) is already up-to-date.")
            return
        }
        
        TickerConnector.fetchPriceHistory(for: tradingPair, since: downloadStartDate, completion: { result in
            switch result {
            case let .success(priceHistory):
                let context = AppDelegate.viewContext
                
                for price in priceHistory {
                    do {
                        let date = price.date as Date
                        // leave out result for today
                        if !date.isToday {
                            _ = try TickerPrice.createTickerPrice(from: price, in: context)
                        }
                    } catch {
                        print("Failed to create tickerPrice from: \(price, error)")
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        print("Saved price history for \(tradingPair.rawValue) with \(priceHistory.count-1) prices since \(downloadStartDate).")
                    }
                    
                    if let completion = completion {
                        completion()
                    }
                } catch {
                    print("Failed to save fetched contract transaction history: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch price history for \(tradingPair.rawValue): \(error)")
            }
        })
    }
    
}
