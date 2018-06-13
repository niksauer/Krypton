//
//  ExchangeRate.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

enum ExchangeRateError: Error {
    case duplicate
}

class ExchangeRate: NSManagedObject {
    
    // MARK: - Public Class Methods
    /// creates and returns ticker exchangeRate if non-existent in database, throws otherwise
    class func createExchangeRate(from prototype: ExchangeRatePrototype, in context: NSManagedObjectContext) throws -> ExchangeRate {
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        
        let startDate = prototype.date.UTCStart
        let endDate = prototype.date.UTCEnd
        
        request.predicate = NSPredicate(format: "base = %@ AND quote = %@ AND date >= %@ AND date < %@", prototype.currencyPair.base.code, prototype.currencyPair.quote.code, startDate as NSDate, endDate as NSDate)
        
        let matches = try context.fetch(request)
        
        if matches.count > 0 {
            assert(matches.count >= 1, "ExchangeRate.createExchangeRate -- Database Inconsistency")
            throw ExchangeRateError.duplicate
        }
        
        let exchangeRate = ExchangeRate(context: context)
        
        exchangeRate.date = prototype.date
        exchangeRate.base = prototype.currencyPair.base.code
        exchangeRate.quote = prototype.currencyPair.quote.code
        exchangeRate.value = prototype.value
        
        return exchangeRate
    }
        
}
