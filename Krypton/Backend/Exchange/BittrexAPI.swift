//
//  BittrexAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 09.11.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

enum BittrexError: Error {
    case invalidJSONData
}

struct BittrexAPI: Exchange {
    
    // MARK: - Private Properties
    private static let baseURL = "https://bittrex.com/api/v1.1/public"
    
    private enum Method: String {
        case CurrentExchangeRate = "getticker"
    }
    
    // MARK: - Private Methods
    private static func bittrexURL(method: Method, parameters: [String: String]) -> URL {
        var components = URLComponents(string:  baseURL.appending("/" + method.rawValue))!
        var queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    // MARK: - Public Methods
    // MARK: Data Aggregation
    static func exchangeRateHistory(for currencyPair: CurrencyPair, fromJSON data: Data) -> ExchangeRateHistoryResult {
        preconditionFailure("This method must be overridden")
    }
    
    static func currentExchangeRate(for currencyPair: CurrencyPair, fromJSON data: Data) -> CurrentExchangeRateResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let lastClosedValue = result["Last"] as? Double else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            let currentExchangeRate = TickerConnector.ExchangeRate(date: Date(), currencyPair: currencyPair, value: lastClosedValue)
            
            return .success(currentExchangeRate)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: URL Creation
    static func exchangeRateHistoryURL(for currencyPair: CurrencyPair, since date: Date) -> URL {
        preconditionFailure("This method must be overridden")
    }
    
    static func currentExchangeRateURL(for currencyPair: CurrencyPair) -> URL {
        return bittrexURL(method: .CurrentExchangeRate, parameters: [
            "market": "\(currencyPair.quote.code)-\(currencyPair.base.code)"
        ])
    }
    
}
