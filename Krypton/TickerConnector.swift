//
//  TickerConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum PriceHistoryResult {
    case success([TickerConnector.Price])
    case failure(Error)
}

enum CurrentPriceResult {
    case success(TickerConnector.Price)
    case failure(Error)
}

struct TickerConnector {
    
    // MARK: - Private Properties
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Public Properties
    struct Price {
        let date: Date
        let currencyPair: CurrencyPair
        let value: Double
    }
    
    // MARK: - Private Methods
    private static func processPriceHistoryRequest(for currencyPair: CurrencyPair, data: Data?, error: Error?) -> PriceHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.priceHistory(for: currencyPair, fromJSON: jsonData)
    }
    
    private static func processCurrentPriceRequest(for currencyPair: CurrencyPair, data: Data?, error: Error?) -> CurrentPriceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        switch currencyPair.base {
        case is Token:
            return BittrexAPI.currentRate(for: currencyPair, fromJSON: jsonData)
        default:
            return KrakenAPI.currentRate(for: currencyPair, fromJSON: jsonData)
        }
    }
    
    // MARK: - Public Methods
    static func fetchPriceHistory(for currencyPair: CurrencyPair, since: Date, completion: @escaping (PriceHistoryResult) -> Void) {
        let url = KrakenAPI.priceHistoryURL(for: currencyPair, since: since)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processPriceHistoryRequest(for: currencyPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    static func fetchCurrentPrice(for currencyPair: CurrencyPair, completion: @escaping (CurrentPriceResult) -> Void) {
        let url: URL
        
        switch currencyPair.base {
        case is Token:
            url = BittrexAPI.currentRateURL(for: currencyPair)
        default:
            url = KrakenAPI.currentRateURL(for: currencyPair)
        }
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processCurrentPriceRequest(for: currencyPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
}
