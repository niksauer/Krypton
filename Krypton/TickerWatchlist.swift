//
//  TickerWatchlist.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class TickerWatchlist {
    
    // MARK: - Public Properties
    static var delegate: TickerWatchlistDelegate?
    
    // MARK: - Private Properties
    private static var currentPrice: [Currency.TradingPair : Double] = [:]
    private static var updateTimer: Timer?
    private static var updateIntervall: TimeInterval = 30
    
    // MARK: - Public Class Methods
    /// adds trading pair to watchlist, fetches current price if trading pair has not already been added
    class func addTradingPair(_ tradingPair: Currency.TradingPair) {
        if currentPrice[tradingPair] == nil {
            updatePrice(for: tradingPair)
            startUpdateTimer()
        }
    }
    
    /// returns current price for tradingPair
    class func currentPrice(for tradingPair: Currency.TradingPair) -> Double? {
        return currentPrice[tradingPair]
    }
    
    /// updates current price every 30 seconds for all tradingPairs stored in watchlist
    /// gets started with first added tradingPair
    class func startUpdateTimer() {
        guard updateTimer == nil else {
            return
        }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateIntervall, repeats: true, block: { _ in
            for (tradingPair, _) in currentPrice {
                updatePrice(for: tradingPair)
            }
        })
    }
    
    // MARK: - Private Class Methods
    /// updates current price for trading pair
    private class func updatePrice(for tradingPair: Currency.TradingPair) {
        TickerConnector.fetchCurrentPrice(for: tradingPair, completion: { result in
            switch result {
            case let .success(currentPrice):
                self.currentPrice[tradingPair] = currentPrice.value
                print("Updated current price for trading pair \(tradingPair.rawValue): \(currentPrice.value)")
                delegate?.didUpdateCurrentPrice(for: tradingPair)
            case let .failure(error):
                print("Failed to fetch current price for trading pair \(tradingPair.rawValue): \(error)")
            }
        })
    }
    
}

protocol TickerWatchlistDelegate {
    func didUpdateCurrentPrice(for tradingPair: Currency.TradingPair)
}
