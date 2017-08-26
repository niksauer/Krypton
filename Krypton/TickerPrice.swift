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
    
    // MARK: - Class Methods
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
    
    class func getTransactionValue(for transaction: Transaction) -> Double? {
        var transactionValue: Double?
        
        if transaction.userExchangeValue != -1 {
            transactionValue = transaction.userExchangeValue
        } else {
            let tradingPair = Currency.getTradingPair(cryptoCurrency: Currency.Crypto(rawValue: (transaction.owner?.cryptoCurrency)!)!, fiatCurrency: Wallet.baseCurrency)!
            if let unitExchangeValue = TickerPrice.getExchangeValue(for: tradingPair, on: transaction.date!) {
                transactionValue = unitExchangeValue * transaction.value
            }
        }
        
        return transactionValue
    }
    
    // MARK: - Private Methods
    private static func getExchangeValue(for tradingPair: Currency.TradingPair, on date: NSDate) -> Double? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date as Date)
        let startDate = calendar.date(from: dateComponents)!
        let endDate = calendar.date(byAdding: .day, value: +1, to: startDate as Date)!
        
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "tradingPair = %@ AND date >= %@ AND date < %@", tradingPair.rawValue, startDate as NSDate, endDate as NSDate)
        
        do {
            let matches = try context.fetch(request)
            
            if matches.count > 0 {
                assert(matches.count >= 1, "Address.addAddress -- Database Inconsistency")
                return matches[0].value
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    //    private func getCurrentTransactionValue(for transaction: Transaction) -> Double? {
    //        var transactionValue: Double?
    //
    //        if transaction.userExchangeValue != -1 {
    //            transactionValue = transaction.userExchangeValue * transaction.value
    //        } else {
    //            let tradingPair = Currency.getTradingPair(cryptoCurrency: Currency.Crypto(rawValue: (transaction.owner?.cryptoCurrency)!)!, fiatCurrency: Wallet.baseCurrency)!
    //            if let unitExchangeValue = getExchangeValue(for: tradingPair, on: transaction.date!) {
    //                transactionValue = unitExchangeValue * transaction.value
    //            }
    //        }
    //
    //        return transactionValue
    //    }
}
