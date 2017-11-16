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

struct KrakenAPI {
    
    // MARK: - Private Properties
    private static let baseURL = "https://api.kraken.com/0/public"
    
    private enum Method: String {
        case priceHistory = "OHLC"
        case currentRate = "Ticker"
    }
    
    private enum Interval {
        case day
    }
    
    private static let resultForCurrencyPair: [String: String] = [
        "ETHEUR" : "XETHZEUR",
        "ETHUSD": "XETHZUSD",
        "XBTEUR": "XXBTZEUR",
        "XBTUSD": "XXBTZUSD",
    ]
    
    private static let minutesForInterval: [Interval: Int] = [
        .day: 1440
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
    static func priceHistory(for currencyPair: CurrencyPair, fromJSON data: Data) -> PriceHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[currencyPair.name], let pricesArray = result[resultName] as? [[Any]] else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            var priceHistory = [TickerConnector.Price]()
            
            for priceJSON in pricesArray {
                if let time = priceJSON[0] as? Double, let valueString = priceJSON[4] as? String, let value = Double(valueString) {
                    let price = TickerConnector.Price(date: Date(timeIntervalSince1970: time), currencyPair: currencyPair, value: value)
                    priceHistory.append(price)
                }
            }
            
            if priceHistory.isEmpty && !pricesArray.isEmpty {
                return .failure(KrakenError.invalidJSONData)
            }
            
            return .success(priceHistory)
        } catch {
            return .failure(error)
        }
    }
    
    static func currentRate(for currencyPair: CurrencyPair, fromJSON data: Data) -> CurrentPriceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[currencyPair.name], let tickerData = result[resultName] as? [String: Any], let lastClosedArray = tickerData["c"] as? [String], let lastClosedValue = Double(lastClosedArray[0]) else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            let currentRate = TickerConnector.Price(date: Date(), currencyPair: currencyPair, value: lastClosedValue)
            
            return .success(currentRate)
        } catch {
            return .failure(error)
        }
    }

    // https://www.kraken.com/help/api
    // <time>, <"open">, <"high">, <"low">, <"close">, <"vwap">, <"volume">, <count>
    static func priceHistoryURL(for currencyPair: CurrencyPair, since: Date) -> URL {
        let sinceDate = Calendar.current.date(byAdding: .day, value: -1, to: since)
        return krakenURL(method: .priceHistory, parameters: [
            "pair": currencyPair.name,
            "interval": String(minutesForInterval[Interval.day]!),
            "since": String(Int(round(sinceDate!.timeIntervalSince1970)))
        ])
    }
    
    // <ask>, <bid>, <last trade>, <volume>, <volume weighted avg price>, <trade count>, <low>, <high>, <open>
    static func currentRateURL(for currencyPair: CurrencyPair) -> URL {
        return krakenURL(method: .currentRate, parameters: [
            "pair": currencyPair.name
        ])
    }
    
}
