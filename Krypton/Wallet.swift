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
    var addresses = [Address]()
    
//    "0xAA2F9BFAA9Ec168847216357b0856d776F34881f"
    
    init() {
//        TickerConnector.fetchCurrentPrice(as: .ETHUSD, completion: { (currentPriceResult) in
//            print(currentPriceResult)
//        })
//
//        TickerConnector.fetchPriceHistory(as: .ETHUSD, completion: { (priceHistoryResult) in
//            print(priceHistoryResult)
//        })
    }
    
    func addAddress(_ address: Address) {
//        addresses.append(address)
//        saveWallet()
    
        EtherConnector.fetchBalance(for: address, completion: { (result) in
            switch result {
            case let .success(balance):
                address.balance = balance
//                self.saveWallet()
            case let .failure(error):
                print(error)
            }
        })
        
        EtherConnector.fetchTransactionHistory(for: address, type: .normal, completion: { (result) in
            switch result {
            case let .success(transactions):
                address.addToTransactions(NSSet(array: transactions))
//                self.saveWallet()
            case let .failure(error):
                print(error)
            }
        })

        EtherConnector.fetchTransactionHistory(for: address, type: .contract, completion: { (result) in
            switch result {
            case let .success(transactions):
                address.addToTransactions(NSSet(array: transactions))
//                self.saveWallet()
            case let .failure(error):
                print(error)
            }
        })
    }
    
    func deleteAddress(_ address: Address) {
        let context = AppDelegate.viewContext
        context.delete(address)
    }
    
    func saveWallet() {
        do {
            let context = AppDelegate.viewContext
            try context.save()
            print("Saved changes to CoreData.")
        } catch {
            print(error)
        }
    }
}
