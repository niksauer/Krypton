//
//  BitcoinTransaction.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class BitcoinTransaction: Transaction {
    
    // MARK: - Public Properties
    var storedAmountFromSender: [String: Double] {
        return amountFromSender as! [String: Double]
    }
    
    var storedAmountForReceiver: [String: Double] {
        return amountForReceiver as! [String: Double]
    }
    
}
