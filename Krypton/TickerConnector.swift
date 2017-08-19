//
//  TickerConnector.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

struct TickerConnector {
    // MARK: - Private Properties
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Private Methods
    private static func processPriceHistoryRequest(as currencyPair: CurrencyPair, data: Data?, error: Error?) -> PriceHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.priceHistory(as: currencyPair, fromJSON: jsonData)
    }
    
    private static func processCurrentPriceRequest(as currencyPair: CurrencyPair, data: Data?, error: Error?) -> CurrentPriceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.currentPrice(as: currencyPair, fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    static func fetchPriceHistory(as currencyPair: CurrencyPair, completion: @escaping (PriceHistoryResult) -> Void) {
        let url = KrakenAPI.priceHistoryURL(for: currencyPair)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processPriceHistoryRequest(as: currencyPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    static func fetchCurrentPrice(as currencyPair: CurrencyPair, completion: @escaping (CurrentPriceResult) -> Void) {
        let url = KrakenAPI.currentPriceURL(for: currencyPair)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processCurrentPriceRequest(as: currencyPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
}
