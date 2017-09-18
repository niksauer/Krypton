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
        request.predicate = NSPredicate(format: "date = %@ AND tradingPair = %@", priceInfo.date, priceInfo.tradingPair.rawValue)
        
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
        guard !date.isUTCToday, !date.isUTCFuture else {
            return nil
        }
    
        let startDate = date.UTCStart
        let endDate = date.UTCEnd
        
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
        var startDate: Date!
        
        if TickerPrice.tickerPrice(for: tradingPair, on: date) == nil {
            startDate = date.UTCStart
        } else if let newestExchangeValueDate = newestTickerPrice(for: tradingPair)?.date {
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: newestExchangeValueDate as Date)!.UTCStart
        }
        
        guard !startDate.isUTCToday, !startDate.isUTCFuture else {
            print("Price history for trading pair \(tradingPair) is already up-to-date.")
            
            if let completion = completion {
                completion()
            }
            
            return
        }
        
        TickerConnector.fetchPriceHistory(for: tradingPair, since: startDate, completion: { result in
            switch result {
            case let .success(priceHistory):
                let context = AppDelegate.viewContext
                
                for price in priceHistory {
                    do {
                        let date = price.date as Date
            
                        // leave out result for today
                        if !date.isUTCToday {
                            _ = try TickerPrice.createTickerPrice(from: price, in: context)
                        }
                    } catch {
                        print("Failed to create tickerPrice from: \(price, error)")
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        print("Saved price history for \(tradingPair.rawValue) with \(priceHistory.count-1) prices since \(startDate!).")
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
