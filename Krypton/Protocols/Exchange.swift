//
//  Exchange.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

struct ExchangeRatePrototype {
    let date: Date
    let currencyPair: CurrencyPair
    let value: Double
}

protocol Exchange {
    func fetchCurrentExchangeRate(for currencyPair: CurrencyPair, completion: @escaping (ExchangeRatePrototype?, Error?) -> Void)
    func fetchExchangeRateHistory(for currencyPair: CurrencyPair, since date: Date, completion: @escaping ([ExchangeRatePrototype]?, Error?) -> Void)
}
