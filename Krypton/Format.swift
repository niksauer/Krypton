//
//  Format.swift
//  Krypton
//
//  Created by Niklas Sauer on 26.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct Format {
    
    // MARK: - Public Properties
    /// formats dates, disregards time
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// formats crypto currency values with 2-4 decimal digits, DOES NOT include currency symbol > use Currency.symbol(for:)
    static let cryptoFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter
    }()
    
    /// formats fiat currency values according to specified wallet base currency
    static let fiatFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Wallet.baseCurrency.rawValue
        return formatter
    }()
    
}

