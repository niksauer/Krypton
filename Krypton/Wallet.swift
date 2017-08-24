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
    
    // MARK: - Properties
    var addresses = [Address]()
    let database = AppDelegate.persistentContainer
    let baseCurrency = Currency.Fiat.EUR
    
    // MARK: - Initialization
    init() {
//        deleteAddresses()
//        deleteTransactions()
        
        do {
            addresses = try loadAddresses()
            print("Loaded \(addresses.count) addresses.")
            
            for address in addresses {
//                address.updateTransactionHistory(in: AppDelegate.viewContext)
                print("\(address.address!): \(address.balance) ETH, \(address.transactions?.count ?? 0) transaction(s).")
            }
            
            updatePriceHistory()
        } catch {
            print("Failed to load addresses: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func addAddress(_ addressString: String, unit: Currency.Crypto) throws {
        do {
            let context = AppDelegate.viewContext
            let address = try Address.createAddress(addressString, unit: unit, in: context)
            
            do {
                try context.save()
                self.addresses.append(address)
                address.updateBalance(in: context)
                address.updateTransactionHistory(in: context)
                updatePriceHistory()
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
    
    func updatePriceHistory() {
        var tradingPairs = Set<Currency.TradingPair>()
        
        for address in addresses {
            if let cryptoCurrency = Currency.Crypto(rawValue: address.cryptoCurrency!), let tradingPair = Currency.getTradingPair(cryptoCurrency: cryptoCurrency, fiatCurrency: baseCurrency) {
                tradingPairs.insert(tradingPair)
            }
        }
        
        for tradingPair in tradingPairs {
            TickerConnector.fetchPriceHistory(for: tradingPair, completion: { result in
                switch result {
                case let .success(priceHistory):
                    let context = AppDelegate.viewContext
                    
                    for price in priceHistory {
                        do {
                            _ = try TickerPrice.createTickerPrice(from: price, in: context)
                        } catch {
//                            print("Failed to create tickerPrice from: \(price, error)")
                        }
                    }
                    
                    do {
                        if context.hasChanges {
                            try context.save()
                            print("Saved price history for \(tradingPair.rawValue) with \(priceHistory.count) prices.")
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

    // MARK: - Private Methods
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
    
}
