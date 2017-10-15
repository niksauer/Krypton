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
        let tradingPair: TradingPair
        let value: Double
    }
    
    // MARK: - Private Methods
    private static func processPriceHistoryRequest(for tradingPair: TradingPair, data: Data?, error: Error?) -> PriceHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.priceHistory(for: tradingPair, fromJSON: jsonData)
    }
    
    private static func processCurrentPriceRequest(for tradingPair: TradingPair, data: Data?, error: Error?) -> CurrentPriceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.currentPrice(for: tradingPair, fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    static func fetchPriceHistory(for tradingPair: TradingPair, since: Date, completion: @escaping (PriceHistoryResult) -> Void) {
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
    
    static func fetchCurrentPrice(for tradingPair: TradingPair, completion: @escaping (CurrentPriceResult) -> Void) {
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
