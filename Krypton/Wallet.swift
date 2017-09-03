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
    /// base fiat currency used to construct trading pairs
    static var baseCurrency = Currency.Fiat.EUR
    
    /// delegate who gets notified of wallet changes
    var delegate: WalletDelegate?
    
    /// stored addresses associated with wallet
    var addresses = [Address]()
    
    /// returns the current summed exchange value of all addresses
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
    /// loads and updates all stored addresses, request continious ticker price updates
    init() {
//        deleteAddresses()
//        deleteTransactions()
//        deletePriceHistory()
        
        do {
            addresses = try loadAddresses()
            print("Loaded \(addresses.count) addresses.")
            updateWallet()
            
            for address in addresses {
                TickerWatchlist.addTradingPair(address.tradingPair)
            }
        } catch {
            print("Failed to load addresses: \(error)")
        }
    }
    
    // MARK: - Public Methods
    /// creates and saves address, sets wallet as its delegate
    /// updates its balance, transaction history, price history and requests continious ticker updates for its trading pair
    func addAddress(_ addressString: String, unit: Currency.Crypto) throws {
        do {
            let context = AppDelegate.viewContext
            let address = try Address.createAddress(addressString, unit: unit, in: context)
            
            do {
                try context.save()
                
                address.delegate = self
                addresses.append(address)
                
                address.updateTransactionHistory(in: context) {
                    address.updatePriceHistory() {
                        TickerWatchlist.addTradingPair(address.tradingPair)
                        address.updateBalance(in: context)
                    }
                }
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
    
    /// returns relative, i.e. percentage, return compared to specified date 
    func relativeReturn(since date: Date) -> Double? {
        guard let currentExchangeValue = currentExchangeValue, let comparisonExchangeValue = exchangeValue(on: date) else {
            return nil
        }
        
        let difference = currentExchangeValue - comparisonExchangeValue
        return difference / comparisonExchangeValue * 100
    }
    
    /// returns summed absolute return history of all addresses since specified date, nil if date is today or in the future
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
            } else {
                return nil
            }
        }
        
        return returnHistory
    }
    
    /// returns summed exchange value of all addresses on speicfied date, nil if date is today or in the future
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
    
    /// updates all addresses stored in wallet by updating transaction history, price history and balance
    func updateWallet() {
        let context = AppDelegate.viewContext
        
        for address in addresses {
            print("\(address.address!): \(address.balance) ETH, \(address.transactions?.count ?? 0) transaction(s).")
            
            address.updateTransactionHistory(in: context) {
                address.updatePriceHistory() {
                    address.updateBalance(in: context)
                }
            }
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
    
    // MARK: - Address Delegate
    /// notifies delegate that balance has changed for specified address
    func didUpdateBalance(for address: Address) {
        delegate?.didUpdateWallet(self)
    }

    
    
    // MARK: - Experimental
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

