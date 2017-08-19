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
    var addresses = [NSManagedObject]()
    
    let address = "0xAA2F9BFAA9Ec168847216357b0856d776F34881f"
    
    init() {
        TickerConnector.fetchCurrentPrice(completion: { (currentPriceResult) in
            print(currentPriceResult)
        })
        
        EtherConnector.fetchTransactionHistory(for: address, type: .contract, completion: { (transactionHistoryResult) in
            print(transactionHistoryResult)
        })
        
        TickerConnector.fetchPriceHistory(completion: { (priceHistoryResult) in
            print(priceHistoryResult)
        })

        EtherConnector.fetchTransactionHistory(for: address, type: .normal, completion: { (transactionHistoryResult) in
            print(transactionHistoryResult)
        })

        EtherConnector.fetchBalance(for: address, completion: { (balanceResult) in
            print(balanceResult)
        })
    }
}
