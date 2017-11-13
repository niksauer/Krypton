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
        case currentRate = "getticker"
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
    static func currentRate(for currencyPair: CurrencyPair, fromJSON data: Data) -> CurrentPriceResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let result = jsonDictionary["result"] as? [String: Any], let lastClosedValue = result["Last"] as? Double else {
                return .failure(KrakenError.invalidJSONData)
            }
            
            let currentRate = TickerConnector.Price(date: Date(), currencyPair: currencyPair, value: lastClosedValue)
            
            return .success(currentRate)
        } catch {
            return .failure(error)
        }
    }
    
    static func currentRateURL(for currencyPair: CurrencyPair) -> URL {
        return bittrexURL(method: .currentRate, parameters: [
            "market": "\(currencyPair.quote.code)-\(currencyPair.base.code)"
        ])
    }
    
}
