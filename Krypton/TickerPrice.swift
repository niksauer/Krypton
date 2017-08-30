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
    
    /// fetches and saves price history for given trading pair starting from newestExchangeValue
    private class func updatePriceHistory(for tradingPair: Currency.TradingPair) {
        guard let newestExchangeValue = newestTickerPrice(for: tradingPair) else {
            print("No price history found for \(tradingPair) - Please fetch price history startinng from specified date.")
            return
        }
        
        updatePriceHistory(for: tradingPair, since: newestExchangeValue.date! as Date)
    }
    
    // MARK: - Public Class Methods
    /// creates and returns a tickerPrice if non-existent in database, throws otherwise
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
    
    /// returns exchange value for given trading pair on specified date
    class func tickerPrice(for tradingPair: Currency.TradingPair, on date: Date) -> TickerPrice? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        let startDate = calendar.date(from: dateComponents)!
        let endDate = calendar.date(byAdding: .day, value: +1, to: startDate)!
        
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

    /// fetches and saves price history for given trading pair starting from specified date
    class func updatePriceHistory(for tradingPair: Currency.TradingPair, since date: Date) {
        guard TickerPrice.tickerPrice(for: tradingPair, on: date) == nil else {
            updatePriceHistory(for: tradingPair)
            return
        }
        
        TickerConnector.fetchPriceHistory(for: tradingPair, since: date, completion: { result in
            switch result {
            case let .success(priceHistory):
                let context = AppDelegate.viewContext
                
                for price in priceHistory {
                    do {
                        _ = try TickerPrice.createTickerPrice(from: price, in: context)
                    } catch {
                        print("Failed to create tickerPrice from: \(price, error)")
                    }
                }
                
                do {
                    if context.hasChanges {
                        try context.save()
                        print("Saved price history for \(tradingPair.rawValue) with \(priceHistory.count) prices since \(date).")
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
