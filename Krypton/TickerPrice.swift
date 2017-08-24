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
    
}
