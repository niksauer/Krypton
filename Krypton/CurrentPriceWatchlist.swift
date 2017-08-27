//
//  CurrentPriceWatchlist.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class CurrentPriceWatchlist {
    
    // MARK: - Private Properties
    private static var currentPrice: [Currency.TradingPair : Double] = [:]
    
    // MARK: - Public Class Methods
    /// adds trading pair to watchlist, fetches current price if trading pair has not already been added
    class func addTradingPair(_ tradingPair: Currency.TradingPair) {
        if currentPrice[tradingPair] == nil {
            updatePrice(for: tradingPair)
        }
    }
    
    class func currentPrice(for tradingPair: Currency.TradingPair) -> Double? {
        return currentPrice[tradingPair]
    }
    
    class func startUpdateTimer(for tradingPair: Currency.TradingPair) {
        
    }
    
    // MARK: - Private Class Methods
    /// updates current price for trading pair
    private class func updatePrice(for tradingPair: Currency.TradingPair) {
        TickerConnector.fetchCurrentPrice(for: tradingPair, completion: { result in
            switch result {
            case let .success(currentPrice):
                self.currentPrice[tradingPair] = currentPrice.value
                print("Updated current price for trading pair \(tradingPair.rawValue): \(currentPrice.value)")
            case let .failure(error):
                print("Failed to fetch current price for trading pair \(tradingPair.rawValue): \(error)")
            }
        })
    }
    
}
