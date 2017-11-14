//
//  Fiat.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.11.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum Fiat: String, Currency {
    
    case EUR
    case USD
    
    // MARK: - Private Properties
    private static let nameForFiat: [Fiat: String] = [
        .EUR: "Euro",
        .USD: "Dollar"
    ]
    
    private static let symbolForFiat: [Fiat: String] = [
        .EUR : "€",
        .USD : "$"
    ]
    
    // MARK: - Public Properties
    static var allValues: [Currency] {
        return [EUR, USD]
    }
    
    // MARK: - Currency Protocol
    var code: String {
        return self.rawValue
    }
    
    var name: String {
        return Fiat.nameForFiat[self]!
    }
    
    var symbol: String {
        return Fiat.symbolForFiat[self]!
    }
    
    var decimalDigits: Int {
        return 2
    }
    
    var type: CurrencyType {
        return .Fiat
    }
    
}
