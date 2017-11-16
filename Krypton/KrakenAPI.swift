//
//  KrakenAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum KrakenError: Error {
    case invalidJSONData
}

struct KrakenAPI: Exchange {
    
    // MARK: - Private Properties
    private static let baseURL = "https://api.kraken.com/0/public"
    
    private enum Method: String {
        case ExchangeRateHistory = "OHLC"
        case CurrentExchangeRate = "Ticker"
    }
    
    private static let resultForCurrencyPair: [String: String] = [
        "ETHEUR" : "XETHZEUR",
        "ETHUSD": "XETHZUSD",
        "XBTEUR": "XXBTZEUR",
        "XBTUSD": "XXBTZUSD",
    ]
    
    // MARK: - Private Methods
    private static func krakenURL(method: Method, parameters: [String: String]) -> URL {
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
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[currencyPair.name], let pricesArray = result[resultName] as? [[Any]] else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            var exchangeRateHistory = [TickerConnector.ExchangeRate]()
            
            for priceJSON in pricesArray {
                if let time = priceJSON[0] as? Double, let valueString = priceJSON[4] as? String, let value = Double(valueString) {
                    let price = TickerConnector.ExchangeRate(date: Date(timeIntervalSince1970: time), currencyPair: currencyPair, value: value)
                    exchangeRateHistory.append(price)
                }
            }
            
            if exchangeRateHistory.isEmpty && !pricesArray.isEmpty {
                return .failure(KrakenError.invalidJSONData)
            }
            
            return .success(exchangeRateHistory)
        } catch {
            return .failure(error)
        }
    }
    
    static func currentExchangeRate(for currencyPair: CurrencyPair, fromJSON data: Data) -> CurrentExchangeRateResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[currencyPair.name], let tickerData = result[resultName] as? [String: Any], let lastClosedArray = tickerData["c"] as? [String], let lastClosedValue = Double(lastClosedArray[0]) else {
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
        let sinceDate = Calendar.current.date(byAdding: .day, value: -1, to: date)
        
        return krakenURL(method: .ExchangeRateHistory, parameters: [
            "pair": currencyPair.name,
            "interval": "1440",
            "since": String(Int(round(sinceDate!.timeIntervalSince1970)))
        ])
    }
    
    static func currentExchangeRateURL(for currencyPair: CurrencyPair) -> URL {
        return krakenURL(method: .CurrentExchangeRate, parameters: [
            "pair": currencyPair.name
        ])
    }
    
}
