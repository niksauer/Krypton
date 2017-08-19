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
    case success([TickerPrice])
    case failure(Error)
}

enum CurrentPriceResult {
    case success(TickerPrice)
    case failure(Error)
}

enum CurrencyPair: String {
    case ETHEUR
    case ETHUSD
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
    static func priceHistory(as currencyPair: CurrencyPair, fromJSON data: Data) -> PriceHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[currencyPair.rawValue], let pricesArray = result[resultName] as? [[Any]] else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            var priceHistory = [TickerPrice]()
            
            for priceJSON in pricesArray {
                if let time = priceJSON[0] as? Double, let valueString = priceJSON[4] as? String, let value = Double(valueString) {
                    let context = AppDelegate.viewContext
                    let price = TickerPrice(context: context)
                    price.date = NSDate(timeIntervalSince1970: time)
                    price.value = value
                    
                    let tickerPair = TickerPair(context: price.managedObjectContext!)
                    tickerPair.currencyPair = currencyPair.rawValue
                    price.tickerPair = tickerPair
                    
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
    
    static func currentPrice(as currencyPair: CurrencyPair, fromJSON data: Data) -> CurrentPriceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let resultName = resultForCurrencyPair[currencyPair.rawValue], let tickerData = result[resultName] as? [String: Any], let lastClosedArray = tickerData["c"] as? [String], let lastClosedValue = Double(lastClosedArray[0])  else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            let context = AppDelegate.viewContext
            let currentPrice = TickerPrice(context: context)
            currentPrice.date = NSDate()
            currentPrice.value = lastClosedValue
            
            let tickerPair = TickerPair(context: currentPrice.managedObjectContext!)
            tickerPair.currencyPair = currencyPair.rawValue
            currentPrice.tickerPair = tickerPair
            
            return .success(currentPrice)
        } catch let error {
            return .failure(error)
        }
    }
    
    // MARK: - Public Properties
    // https://www.kraken.com/help/api
    
    // <time>, <"open">, <"high">, <"low">, <"close">, <"vwap">, <"volume">, <count>
    static func priceHistoryURL(for currencyPair: CurrencyPair) -> URL {
        let since = Calendar.current.date(byAdding: .day, value: -32, to: Date())!
        
        return krakenURL(method: .priceHistory, parameters: [
            "pair": currencyPair.rawValue,
            "interval": "1440",
            "since": String(Int(round(since.timeIntervalSince1970)))
        ])
    }
    
    // <ask>, <bid>, <last trade>, <volume>, <volume weighted avg price>, <trade count>, <low>, <high>, <open>
    static func currentPriceURL(for currencyPair: CurrencyPair) -> URL {
        return krakenURL(method: .currentPrice, parameters: [
            "pair": currencyPair.rawValue
        ])
    }
}
