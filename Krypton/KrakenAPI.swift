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

struct KrakenAPI {
    // MARK: - Private Properties
    private static let baseURL = "https://api.kraken.com/0/public"
    
    private enum Method: String {
        case priceHistory = "OHLC"
        case currentPrice = "Ticker"
    }
    
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
    static func priceHistory(fromJSON data: Data) -> PriceHistoryResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let pricesArray = result["XETHZEUR"] as? [[Any]] else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            var priceHistory = [TickerPrice]()
            
            for priceJSON in pricesArray {
                if let time = priceJSON[0] as? Double, let valueString = priceJSON[4] as? String, let value = Double(valueString) {
//                    let price = TickerPrice(date: Date(timeIntervalSince1970: time), value: value)
                    
                    let context = AppDelegate.viewContext
                    let price = TickerPrice(context: context)
                    price.date = NSDate(timeIntervalSince1970: time)
                    price.value = value
                    
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
    
    static func currentPrice(fromJSON data: Data) -> CurrentPriceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let tickerData = result["XETHZEUR"] as? [String: Any], let lastClosedArray = tickerData["c"] as? [String], let lastClosedValue = Double(lastClosedArray[0])  else {
                return .failure(KrakenError.invalidJSONData)
            }
            
//            let currentPrice = TickerPrice(date: Date(), value: lastClosedValue)
            let context = AppDelegate.viewContext
            let currentPrice = TickerPrice(context: context)
            currentPrice.date = NSDate()
            currentPrice.value = lastClosedValue
            
            return .success(currentPrice)
        } catch let error {
            return .failure(error)
        }
    }
    
    // MARK: - Public Properties
    // https://www.kraken.com/help/api
    
    // <time>, <"open">, <"high">, <"low">, <"close">, <"vwap">, <"volume">, <count>
    static var priceHistoryURL: URL {
        let since = Calendar.current.date(byAdding: .day, value: -32, to: Date())!
        
        return krakenURL(method: .priceHistory, parameters: [
            "pair": "ETHEUR",
            "interval": "1440",
            "since": String(Int(round(since.timeIntervalSince1970)))
        ])
    }
    
    // <ask>, <bid>, <last trade>, <volume>, <volume weighted avg price>, <trade count>, <low>, <high>, <open>
    static var currentPriceURL: URL {
        return krakenURL(method: .currentPrice, parameters: [
            "pair": "ETHEUR"
        ])
    }
}
