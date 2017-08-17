//
//  Price.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class Transaction: CustomStringConvertible {
    // MARK: - Public Properties
    let date: Date
    let value: Double
    let from: String
    let to: String
    
    var description: String {
        return "v: \(value)"
    }
    
    // MARK: - Initializers
    init(date: Date, value: Double, from: String, to: String) {
        self.date = date
        self.value = value
        self.from = from
        self.to = to
    }
}
