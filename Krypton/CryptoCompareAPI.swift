//
//  CryptoCompareAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.11.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum CryptoCompareError: Error {
    case invalidJSONData
}

struct CryptoCompareAPI: Exchange {
    
    // MARK: - Private Properties
    private static let baseURL = "https://min-api.cryptocompare.com/data"
    
    private enum Method: String {
        case ExchangeRateHistory = "histoday"
        case CurrentExchangeRate = "price"
    }
    
    // MARK: - Private Methods
    private static func cryptoCompareURL(method: Method, parameters: [String: String]) -> URL {
        var components = URLComponents(string: baseURL.appending("/\(method.rawValue)"))!
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
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let exchangeRateArray = jsonDictionary["Data"] as? [[String: Any]] else {
                return .failure(CryptoCompareError.invalidJSONData)
            }
            
            var exchangeRateHistory = [TickerConnector.ExchangeRate]()
            
            for exchangeRateJSON in exchangeRateArray {
                if let time = exchangeRateJSON["time"] as? Double, let value = exchangeRateJSON["close"] as? Double {
                    let exchangeRate = TickerConnector.ExchangeRate(date: Date(timeIntervalSince1970: time), currencyPair: currencyPair, value: value)
                    exchangeRateHistory.append(exchangeRate)
                }
            }
            
            if exchangeRateHistory.isEmpty && !exchangeRateArray.isEmpty {
                return .failure(CryptoCompareError.invalidJSONData)
            }
            
            return .success(exchangeRateHistory)
        } catch {
            return .failure(error)
        }
    }
    
    static func currentExchangeRate(for currencyPair: CurrencyPair, fromJSON data: Data) -> CurrentExchangeRateResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any], let value = jsonDictionary[currencyPair.quote.code] as? Double else {
                return .failure(CryptoCompareError.invalidJSONData)
            }
            
            let currentExchangeRate = TickerConnector.ExchangeRate(date: Date(), currencyPair: currencyPair, value: value)
            
            return .success(currentExchangeRate)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: URL Creation
    static func exchangeRateHistoryURL(for currencyPair: CurrencyPair, since date: Date) -> URL {
        let limit = Calendar.current.dateComponents([.day], from: date, to: Date()).day!
    
        return cryptoCompareURL(method: .ExchangeRateHistory, parameters: [
            "fsym": currencyPair.base.code,
            "tsym": currencyPair.quote.code,
            "limit": String(limit)
        ])
    }
    
    static func currentExchangeRateURL(for currencyPair: CurrencyPair) -> URL {
        return cryptoCompareURL(method: .CurrentExchangeRate, parameters: [
            "fsym": currencyPair.base.code,
            "tsyms": currencyPair.quote.code,
        ])
    }

}
