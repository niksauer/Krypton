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

enum PriceHistoryResult {
    case success([KrakenAPI.Price])
    case failure(Error)
}

enum CurrentPriceResult {
    case success(KrakenAPI.Price)
    case failure(Error)
}

struct KrakenAPI {
    // MARK: - Private Properties
    private static let baseURL = "https://api.kraken.com/0/public"
    
    private enum Method: String {
        case priceHistory = "OHLC"
        case currentPrice = "Ticker"
    }
    
    private static let resultForCurrencyPair = [
        "ETHEUR" : "XETHZEUR",
        "ETHUSD" : "XETHZUSD"
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
    static func priceHistory(for tradingPair: Currency.TradingPair, fromJSON data: Data) -> PriceHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[tradingPair.rawValue], let pricesArray = result[resultName] as? [[Any]] else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            var priceHistory = [Price]()
            
            for priceJSON in pricesArray {
                if let time = priceJSON[0] as? Double, let valueString = priceJSON[4] as? String, let value = Double(valueString) {
                    let price = Price(date: NSDate(timeIntervalSince1970: time), tradingPair: tradingPair, value: value)
                    priceHistory.append(price)
                }
            }
            
            if priceHistory.isEmpty && !pricesArray.isEmpty {
                return .failure(KrakenError.invalidJSONData)
            }
            
            return .success(priceHistory)
        } catch let error {
            return .failure(error)
        }
    }
    
    static func currentPrice(for tradingPair: Currency.TradingPair, fromJSON data: Data) -> CurrentPriceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[tradingPair.rawValue], let tickerData = result[resultName] as? [String: Any], let lastClosedArray = tickerData["c"] as? [String], let lastClosedValue = Double(lastClosedArray[0])  else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            let currentPrice = Price(date: NSDate(), tradingPair: tradingPair, value: lastClosedValue)
            
            return .success(currentPrice)
        } catch let error {
            return .failure(error)
        }
    }
    
    // MARK: - Public Properties
    struct Price {
        let date: NSDate
        let tradingPair: Currency.TradingPair
        let value: Double
    }
    
    // https://www.kraken.com/help/api
    
    // <time>, <"open">, <"high">, <"low">, <"close">, <"vwap">, <"volume">, <count>
    static func priceHistoryURL(for tradingPair: Currency.TradingPair, since: Date) -> URL {
        let sinceDate = Calendar.current.date(byAdding: .day, value: -1, to: since)
        return krakenURL(method: .priceHistory, parameters: [
            "pair": tradingPair.rawValue,
            "interval": "1440",
            "since": String(Int(round(sinceDate!.timeIntervalSince1970)))
        ])
    }
    
    // <ask>, <bid>, <last trade>, <volume>, <volume weighted avg price>, <trade count>, <low>, <high>, <open>
    static func currentPriceURL(for tradingPair: Currency.TradingPair) -> URL {
        return krakenURL(method: .currentPrice, parameters: [
            "pair": tradingPair.rawValue
        ])
    }
}
