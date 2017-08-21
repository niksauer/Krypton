//
//  Address.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum CryptoUnit: String {
    case ETH
    case BTC
}

enum AddressError: Error {
    case duplicate
}

class Address: NSManagedObject {
    
    // MARK: - Class Methods
    /// returns new address if non-existent in database, throws otherwise
    class func createAddress(_ addressString: String, unit: CryptoUnit, in context: NSManagedObjectContext) throws -> Address {
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        request.predicate = NSPredicate(format: "address = %@", addressString)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Address.addAddress -- Database Inconsistency")
                throw AddressError.duplicate
            }
        } catch {
            throw error
        }
        
        let address = Address(context: context)
        address.address = addressString
        address.unit = unit.rawValue
        
        return address
    }
    
    // MARK: - Public Methods
    /// fetches and saves balance retrieved via EtherscanAPI
    func updateBalance(in context: NSManagedObjectContext) {
        EtherConnector.fetchBalance(for: self, completion: { result in
            switch result {
            case let .success(balance):
                self.balance = balance
                
                do {
                    try context.save()
                } catch {
                    print("Failed to save fetched balance: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch balance: \(error)")
            }
        })
    }
    
    /// fetches and saves transaction history retrieved via EtherscanAPI
    func updateTransactionHistory(in context: NSManagedObjectContext) {
        EtherConnector.fetchTransactionHistory(for: self, type: .normal, completion: { result in
            switch result {
            case let .success(txs):
                for txInfo in txs {
                    if let transaction = try? Transaction.createTransaction(from: txInfo, in: context) {
                        self.addToTransactions(transaction)
                    }
                }
                
                do {
                    try context.save()
                    print("saved 1")
                } catch {
                    print("Failed to save fetched normal transaction history: \(error)")
                }
            case let .failure(error):
                print("Failed to fetch normal transaction history: \(error)")
            }
        })
        
        EtherConnector.fetchTransactionHistory(for: self, type: .contract, completion: { result in
            switch result {
            case let .success(txs):
                for txInfo in txs {
                    if let transaction = try? Transaction.createTransaction(from: txInfo, in: context) {
                        self.addToTransactions(transaction)
                    }
                }
                
                context.performAndWait {
                    do {
                        try context.save()
                        print("saved 2")
                    } catch {
                        print("Failed to save fetched normal transaction history: \(error)")
                    }
                }
            case let .failure(error):
                print("Failed to fetch contract transaction history: \(error)")
            }
        })
    }

}
