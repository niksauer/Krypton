//
//  BitcoinAddress.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class BitcoinAddress: Address {
    
    // MARK: - Initializers
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Blockchain.Bitcoin.rawValue, forKey: "blockchainRaw")
    }
    
    // MARK: - Public Methods
    // MARK: Cryptography
    override func isValidAddress() -> Bool {
        let regex = NSPredicate(format: "SELF MATCHES %@", "^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$")
        return regex.evaluate(with: identifier!)
    }
    
}
