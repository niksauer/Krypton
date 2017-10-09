//
//  TickerWatchlist.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

final class TickerWatchlist {
    
    // MARK: - Public Properties
    /// delegate who is notified of price updates
    static var delegate: TickerWatchlistDelegate?
    
    // MARK: - Private Properties
    /// dictionary mapping trading pairs to their most current price
    private static var currentPrice: [TradingPair : Double] = [:]
    
    /// timer used to continioulsy fetch price updates
    private static var updateTimer: Timer?
    
    /// price update interval specified in seconds
    private static var updateIntervall: TimeInterval = 30
    
    /// trading pairs for which continious price updates are retrieved
    private static var tradingPairs = Set<TradingPair>()
    
    private static var requestsForTradingPair: [TradingPair : Int] = [:]
    
    // MARK: - Public Class Methods
    /// adds trading pair and fetches current price if it has not already been added to watchlist, starts update timer
    class func addTradingPair(_ tradingPair: TradingPair) {
        if !tradingPairs.contains(tradingPair) {
            tradingPairs.insert(tradingPair)
            updatePrice(for: tradingPair)
        }
        
        if tradingPairs.count == 1 {
            startUpdateTimer()
        }
        
        if let requestCount = requestsForTradingPair[tradingPair] {
            requestsForTradingPair[tradingPair] = requestCount + 1
        } else {
            requestsForTradingPair[tradingPair] = 1
        }
    }
    
    class func removeTradingPair(_ tradingPair: TradingPair) {
        guard let requestCount = requestsForTradingPair[tradingPair], requestCount > 0 else {
            return
        }
        
        tradingPairs.remove(tradingPair)
        requestsForTradingPair[tradingPair] = requestCount - 1
    }
    
    /// returns current price for specified trading pair
    class func getCurrentPrice(for tradingPair: TradingPair) -> Double? {
        return currentPrice[tradingPair]
    }
    
    class func reset() {
        stopUpdateTimer()
        tradingPairs = Set<TradingPair>()
        requestsForTradingPair = [:]
    }
    
    /// starts unique timer to update current price in specified interval for all stored trading pairs
    /// timer stop if app enters background, starts/continues when becoming active again
    @objc class func startUpdateTimer() {
        guard updateTimer == nil else {
            // timer already running
            return
        }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateIntervall, repeats: true, block: { _ in
            for tradingPair in tradingPairs {
                updatePrice(for: tradingPair)
            }
        })
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.setObserver(self, selector: #selector(stopUpdateTimer), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.setObserver(self, selector: #selector(startUpdateTimer), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc class func stopUpdateTimer() {
        guard updateTimer != nil else {
            // no timer set
            return
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Private Class Methods
    /// updates current price for specified trading pair, notifies delegate of change
    private class func updatePrice(for tradingPair: TradingPair) {
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
    func didUpdateCurrentPrice(for tradingPair: TradingPair)
}
