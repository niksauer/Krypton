//
//  Transaction.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum TransactionError: Error {
    case duplicate
}

class Transaction: NSManagedObject {
    
    // MARK: - Class Methods
    /// creates and returns a transaction if non-existent in database, throws otherwise
    class func createTransaction(from txInfo: EtherscanAPI.Transaction, in context: NSManagedObjectContext) throws -> Transaction {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@ AND type = %@", txInfo.identifier, txInfo.type.rawValue)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Transaction.createTransaction -- Database Inconsistency")
                throw TransactionError.duplicate
            }
        } catch {
            throw error
        }
        
        let transaction = Transaction(context: context)
        transaction.date = txInfo.date
        transaction.value = txInfo.value
        transaction.type = txInfo.type.rawValue
        transaction.to = txInfo.to
        transaction.from = txInfo.from
        transaction.identifier = txInfo.identifier
        transaction.block = txInfo.block
        
        return transaction
    }
    
    // MARK: - Public Properties
    /// returns exchange value as encountered on execution date
    var exchangeValue: Double? {
        let tradingPair = Currency.getTradingPair(cryptoCurrency: Currency.Crypto(rawValue: (owner?.cryptoCurrency)!)!, fiatCurrency: Wallet.baseCurrency)!
        
        if let unitExchangeValue = TickerPrice.getTickerPrice(for: tradingPair, on: date! as Date) {
            return unitExchangeValue.value * value
        } else {
            return nil
        }
    }
    
    // MARK: - Public Methods
    /// replaces exchange value as encountered on execution date by user defined value
    func setUserExchangeValue(_ newValue: Double, in context: NSManagedObjectContext) {
        if newValue != userExchangeValue {
            userExchangeValue = newValue
        }
        
        do {
            try context.save()
            print("Saved updated user exchange value.")
        } catch {
            print("Failed to save updated user exchange value.")
        }
    }
    
}

