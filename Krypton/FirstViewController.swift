//
//  FirstViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    // MARK: - Public Properties
    var ticker = TickerStore()
    var wallet = WalletStore()
    
    // MARK: - Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let address = "0xAA2F9BFAA9Ec168847216357b0856d776F34881f"
        
//        ticker.fetchPriceHistory(completion: { (priceHistoryResult) in
//            print(priceHistoryResult)
//        })
//        
//        ticker.fetchCurrentPrice(completion: { (currentPriceResult) in
//            print(currentPriceResult)
//        })
//        
//        wallet.fetchTransactionHistory(for: address, completion: { (transactionHistoryResult) in
//            print(transactionHistoryResult)
//        })
        
//        wallet.fetchTransactionHistory(for: address, type: .normal, completion: { (transactionHistoryResult) in
//            print(transactionHistoryResult)
//        })
        
//        wallet.fetchBalance(for: address, completion: { (balanceResult) in
//            print(balanceResult)
//        })
    }
}
