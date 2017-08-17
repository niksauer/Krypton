//
//  PriceStore.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class TickerStore {
    // MARK: - Private Properties
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: - Private Methods
    private func processPriceHistoryRequest(data: Data?, error: Error?) -> PriceHistoryResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.priceHistory(fromJSON: jsonData)
    }
    
    private func processCurrentPriceRequest(data: Data?, error: Error?) -> CurrentPriceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return KrakenAPI.currentPrice(fromJSON: jsonData)
    }
    
    // MARK: - Public Methods
    func fetchPriceHistory(completion: @escaping (PriceHistoryResult) -> Void) {
        let url = KrakenAPI.priceHistoryURL
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processPriceHistoryRequest(data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    func fetchCurrentPrice(completion: @escaping (CurrentPriceResult) -> Void) {
        let url = KrakenAPI.currentPriceURL
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processCurrentPriceRequest(data: data, error: error)
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
}
