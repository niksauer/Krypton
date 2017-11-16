//
//  TickerConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum ExchangeRateHistoryResult {
    case success([TickerConnector.ExchangeRate])
    case failure(Error)
}

enum CurrentExchangeRateResult {
    case success(TickerConnector.ExchangeRate)
    case failure(Error)
}

protocol Exchange {
    static func exchangeRateHistory(for currencyPair: CurrencyPair, fromJSON data: Data) -> ExchangeRateHistoryResult
    static func currentExchangeRate(for currencyPair: CurrencyPair, fromJSON data: Data) -> CurrentExchangeRateResult
    
    static func exchangeRateHistoryURL(for currencyPair: CurrencyPair, since date: Date) -> URL
    static func currentExchangeRateURL(for currencyPair: CurrencyPair) -> URL
}

struct TickerConnector {
    
    // MARK: - Private Properties
    private static let session = URLSession(configuration: .default)
    
    // MARK: - Public Properties
    struct ExchangeRate {
        let date: Date
        let currencyPair: CurrencyPair
        let value: Double
    }
    
    // MARK: - Private Methods
    private static func processExchangeRateHistoryRequest(for currencyPair: CurrencyPair, data: Data?, error: Error?) -> ExchangeRateHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
    
        return CryptoCompareAPI.exchangeRateHistory(for: currencyPair, fromJSON: jsonData)
    }
    
    private static func processCurrentExchangeRateRequest(for currencyPair: CurrencyPair, data: Data?, error: Error?) -> CurrentExchangeRateResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return CryptoCompareAPI.currentExchangeRate(for: currencyPair, fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    static func fetchExchangeRateHistory(for currencyPair: CurrencyPair, since date: Date, completion: @escaping (ExchangeRateHistoryResult) -> Void) {
        let url = CryptoCompareAPI.exchangeRateHistoryURL(for: currencyPair, since: date)
        let request = URLRequest(url: url)
        
        print(url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processExchangeRateHistoryRequest(for: currencyPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    static func fetchCurrentExchangeRate(for currencyPair: CurrencyPair, completion: @escaping (CurrentExchangeRateResult) -> Void) {
        let url = CryptoCompareAPI.currentExchangeRateURL(for: currencyPair)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processCurrentExchangeRateRequest(for: currencyPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
}
