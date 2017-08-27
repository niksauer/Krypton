//
//  Wallet.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

class Wallet {
    
//    0xAA2F9BFAA9Ec168847216357b0856d776F34881f
//    0xB15E9Ca894b6134Ac7C22B70b20Fd30De87451B2
    
    // MARK: - Public Properties
    static var baseCurrency = Currency.Fiat.EUR
    var addresses = [Address]()
    
    // MARK: - Initialization
    init() {
//        deleteAddresses()
//        deleteTransactions()
//        deletePriceHistory()
        
        do {
            addresses = try loadAddresses()
            print("Loaded \(addresses.count) addresses.")
            
            for address in addresses {
                address.updateTransactionHistory(in: AppDelegate.viewContext, completion: address.updatePriceHistory)
                print("\(address.address!): \(address.balance) ETH, \(address.transactions?.count ?? 0) transaction(s).")
            }
        } catch {
            print("Failed to load addresses: \(error)")
        }
    }
    
    // MARK: - Public Methods
    /// creates and saves new address if non-existent in database, throws otherwise + updates balance, transaction history, price history
    func addAddress(_ addressString: String, unit: Currency.Crypto) throws {
        do {
            let context = AppDelegate.viewContext
            let address = try Address.createAddress(addressString, unit: unit, in: context)
            
            do {
                try context.save()
                
                addresses.append(address)
                address.updateBalance(in: context)
                address.updateTransactionHistory(in: context, completion: address.updatePriceHistory)
                
                let cryptoCurrency = Currency.Crypto(rawValue: address.cryptoCurrency!)!
                let tradingPair = Currency.getTradingPair(cryptoCurrency: cryptoCurrency, fiatCurrency: Wallet.baseCurrency)!
                CurrentPriceWatchlist.addTradingPair(tradingPair)
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }

    // MARK: - Private Methods
    /// loads and returns all available addresses stored in Core Data
    private func loadAddresses() throws -> [Address] {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            throw error
        }
    }
    
    private func loadTransactions() -> [Transaction]? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return try? context.fetch(request)
    }
    
    private func loadPriceHistory() -> [TickerPrice]? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return try? context.fetch(request)
    }
    
    private func deleteAddresses() {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        
        if let result = try? context.fetch(request) {
            for address in result {
                context.delete(address)
            }
        }
        
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
    
    private func deleteTransactions() {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        if let result = try? context.fetch(request) {
            for address in result {
                context.delete(address)
            }
        }
        
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
    
    private func deletePriceHistory() {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
        
        _ = try? context.execute(deleteRequest)
        try? context.save()
    }
    
}


