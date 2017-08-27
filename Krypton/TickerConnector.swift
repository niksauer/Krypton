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
    private static func processPriceHistoryRequest(for tradingPair: Currency.TradingPair, data: Data?, error: Error?) -> PriceHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.priceHistory(for: tradingPair, fromJSON: jsonData)
    }
    
    private static func processCurrentPriceRequest(for tradingPair: Currency.TradingPair, data: Data?, error: Error?) -> CurrentPriceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.currentPrice(for: tradingPair, fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    static func fetchPriceHistory(for tradingPair: Currency.TradingPair, since: Date, completion: @escaping (PriceHistoryResult) -> Void) {
        let url = KrakenAPI.priceHistoryURL(for: tradingPair, since: since)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processPriceHistoryRequest(for: tradingPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    static func fetchCurrentPrice(for tradingPair: Currency.TradingPair, completion: @escaping (CurrentPriceResult) -> Void) {
        let url = KrakenAPI.currentPriceURL(for: tradingPair)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processCurrentPriceRequest(for: tradingPair, data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
}
