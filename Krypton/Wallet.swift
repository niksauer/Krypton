//
//  Wallet.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

class Wallet: AddressDelegate {
    
//    0xAA2F9BFAA9Ec168847216357b0856d776F34881f
//    0xB15E9Ca894b6134Ac7C22B70b20Fd30De87451B2
    
    // MARK: - Public Properties
    static var baseCurrency = Currency.Fiat.EUR
    
    var delegate: WalletDelegate?
    var addresses = [Address]()
    
    var currentExchangeValue: Double? {
        var exchangeValue = 0.0
        for address in addresses {
            if let addressExchangeValue = address.currentExchangeValue {
                exchangeValue = exchangeValue + addressExchangeValue
            } else {
                return nil
            }
        }
        return exchangeValue
    }
    
    // MARK: - Initialization
    init() {
//        deleteAddresses()
//        deleteTransactions()
//        deletePriceHistory()
        
        do {
            let context = AppDelegate.viewContext
            addresses = try loadAddresses()
            print("Loaded \(addresses.count) addresses.")
            
            for address in addresses {
                address.updateBalance(in: context)
                address.updateTransactionHistory(in: context, completion: address.updatePriceHistory)
                print("\(address.address!): \(address.balance) ETH, \(address.transactions?.count ?? 0) transaction(s).")
                TickerWatchlist.addTradingPair(address.tradingPair)
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
                address.delegate = self
                address.updateBalance(in: context)
                address.updateTransactionHistory(in: context, completion: address.updatePriceHistory)
                TickerWatchlist.addTradingPair(address.tradingPair)
                addresses.append(address)
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
    
    func absoluteReturnHistory(since date: Date) -> [(date: Date, value: Double)]? {
        guard !date.isToday(), !date.isFuture() else {
            return nil
        }
        
        var returnHistory: [(Date, Double)] = []
        
        for (index, address) in addresses.enumerated() {
            if let absoluteReturnHistory = address.absolutReturnHistory(since: date) {
                if index == 0 {
                    for (date, absoluteReturn) in absoluteReturnHistory {
                        returnHistory.append((date, absoluteReturn))
                    }
                } else {
                    returnHistory = zip(returnHistory, absoluteReturnHistory).map() { ($0.0, $0.1 + $1.1) }
                }
            }
        }
        
        return returnHistory
    }
    
    func exchangeValue(on date: Date) -> Double? {
        var exchangeValue = 0.0
        for address in addresses {
            if let addressExchangeValue = address.exchangeValue(on: date) {
                exchangeValue = exchangeValue + addressExchangeValue
            } else {
                return nil
            }
        }
        return exchangeValue
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
    
    // MARK: - Address Delegate
    func didUpdateBalance(for address: Address) {
        delegate?.didUpdateWallet(self)
    }
    
    func deleteCoreData() {
        deleteAddresses()
        deleteTransactions()
        deletePriceHistory()
        delegate?.didUpdateWallet(self)
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

protocol WalletDelegate {
    func didUpdateWallet(_ wallet: Wallet)
}

