//
//  Price.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class TickerPrice: CustomStringConvertible {
    // MARK: - Public Properties
    let date: Date
    let value: Double
    
    var description: String {
        return "v: \(value)"
    }
    
    // MARK: - Initializers
    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}
