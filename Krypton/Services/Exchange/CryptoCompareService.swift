//
//  CryptoCompareService.swift
//  Krypton
//
//  Created by Niklas Sauer on 11.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import NetworkKit

struct CryptoCompareService: JSONService, Exchange {

    // MARK: - Service
    let client: JSONAPIClient
    
    init(hostURL: String, port: Int?, credentials: APICredentialStore?) {
        self.client = JSONAPIClient(hostURL: hostURL, port: port, basePath: "data", credentials: nil)
    }
    
    // MARK: - Exchange
    func fetchCurrentExchangeRate(for currencyPair: CurrencyPair, completion: @escaping (ExchangeRatePrototype?, Error?) -> Void) {
        client.makeGETRequest(to: "/price", params: [
            "fsym": currencyPair.base.code,
            "tsyms": currencyPair.quote.code,
        ]) { result in
            let result = self.getJSON(from: result)
            
            guard let json = result.json else {
                completion(nil, result.error!)
                return
            }
            
            guard let value = json[currencyPair.quote.code] as? Double else {
                completion(nil, JSONAPIError.invalidJSON)
                return
            }
            
            let currentExchangeRate = ExchangeRatePrototype(date: Date(), currencyPair: currencyPair, value: value)
            completion(currentExchangeRate, nil)
        }
    }
    
    func fetchExchangeRateHistory(for currencyPair: CurrencyPair, since date: Date, completion: @escaping ([ExchangeRatePrototype]?, Error?) -> Void) {
        client.makeGETRequest(to: "/histoday", params: [
            "fsym": currencyPair.base.code,
            "tsym": currencyPair.quote.code,
            "limit": String(Calendar.current.dateComponents([.day], from: date, to: Date()).day!)
        ]) { result in
            struct ExchangeRate: Codable {
                let time: Double
                let close: Double
            }
            
            let result = self.decode([ExchangeRate].self, from: result, at: "Data")
            
            guard let rawHistory = result.instance else {
                completion(nil, result.error)
                return
            }
            
            let history = rawHistory.map { exchangeRate in
                ExchangeRatePrototype(date: Date(timeIntervalSince1970: exchangeRate.time), currencyPair: currencyPair, value: exchangeRate.close)
            }
            
            completion(history, nil)
        }
    }
 
}

