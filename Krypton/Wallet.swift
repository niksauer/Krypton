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
    
//    "0xAA2F9BFAA9Ec168847216357b0856d776F34881f"
    
    // MARK: - Properties
    var addresses = [Address]()
    let database = AppDelegate.persistentContainer

    // MARK: - Initialization
    init() {
//        deleteAddresses()
//        deleteTransactions()
        
        do {
            addresses = try loadAddresses()
            print("Loaded \(addresses.count) addresses.")
            
            for address in addresses {
                print("\(address.address!): \(address.balance) ETH, \(address.transactions?.count ?? 0) transaction(s).")
            }
        } catch {
            print("Failed to load addresses: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func addAddress(_ addressString: String, unit: CryptoUnit) throws {
        do {
            let context = AppDelegate.viewContext
            let address = try Address.createAddress(addressString, unit: unit, in: context)
            
            do {
                try context.save()
                self.addresses.append(address)
                address.updateBalance(in: context)
                address.updateTransactionHistory(in: context)
            } catch {
                throw error
            }
        } catch {
            throw error
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



//        TickerConnector.fetchCurrentPrice(as: .ETHUSD, completion: { (currentPriceResult) in
//            print(currentPriceResult)
//        })
//
//        TickerConnector.fetchPriceHistory(as: .ETHUSD, completion: { (priceHistoryResult) in
//            print(priceHistoryResult)
//        })

//        EtherConnector.fetchTransactionHistory(for: address, type: .normal, completion: { (result) in
//            switch result {
//            case let .success(transactions):
//                address.addToTransactions(NSSet(array: transactions))
////                self.saveWallet()
//            case let .failure(error):
//                print(error)
//            }
//        })
//
//        EtherConnector.fetchTransactionHistory(for: address, type: .contract, completion: { (result) in
//            switch result {
//            case let .success(transactions):
//                address.addToTransactions(NSSet(array: transactions))
////                self.saveWallet()
//            case let .failure(error):
//                print(error)
//            }
//        })
