//
//  BittrexAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 09.11.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum BittrexError: Error {
    case invalidJSONData
}

struct BittrexAPI {
    
    // MARK: - Private Properties
    private static let baseURL = "https://bittrex.com/api/v1.1/public"
    
    private enum Method: String {
        case currentPrice = "getticker"
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
    static func currentPrice(for tradingPair: TradingPair, fromJSON data: Data) -> CurrentPriceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let lastClosedValue = result["Last"] as? Double else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            let currentPrice = TickerConnector.Price(date: Date(), tradingPair: tradingPair, value: lastClosedValue)
            
            return .success(currentPrice)
        } catch {
            return .failure(error)
        }
    }
    
    static func currentPriceURL(for tradingPair: TradingPair) -> URL {
        return bittrexURL(method: .currentPrice, parameters: [
            "market": "\(tradingPair.quote.code)-\(tradingPair.base.code)"
        ])
    }
    
}
