//
//  TickerDaemon.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

protocol TickerDaemonDelegate {
    func didUpdateCurrentPrice(for tradingPair: TradingPair)
}

final class TickerDaemon {
    
    // MARK: - Public Properties
    /// delegate who is notified of price updates
    static var delegate: TickerDaemonDelegate?
    
//    static var storedTokens = Set<Token>()
    
    // MARK: - Private Properties
    /// timer used to continioulsy fetch price updates
    private static var updateTimer: Timer?
    
    /// price update interval specified in seconds
    private static var updateIntervall: TimeInterval = 30
    
    /// trading pairs for which continious price updates are retrieved
    private static var tradingPairs = Set<TradingPair>()
    
    /// dictionary mapping trading pairs to their most current price
    private static var currentPriceForTradingPair = [TradingPair: Double]()
    
    private static var requestsForTradingPair = [TradingPair: Int]()
    
    // MARK: - Public Class Methods
    /// adds trading pair and fetches current price if it has not already been added to watchlist, starts update timer
    class func addTradingPair(_ tradingPair: TradingPair) {
        if !tradingPairs.contains(tradingPair) {
            tradingPairs.insert(tradingPair)
            updatePrice(for: tradingPair)
            log.debug("Added tradingPair '\(tradingPair.name)' to TickerDaemon.")
        }
    
        if let requestCount = requestsForTradingPair[tradingPair] {
            requestsForTradingPair[tradingPair] = requestCount + 1
            log.debug("Updated requests (\(requestCount + 1)) for tradingPair '\(tradingPair.name)'.")
        } else {
            requestsForTradingPair[tradingPair] = 1
        }
        
        if tradingPairs.count == 1 {
            startUpdateTimer()
        }
    }
    
    class func removeTradingPair(_ tradingPair: TradingPair) {
        guard let requestCount = requestsForTradingPair[tradingPair] else {
            return
        }
        
        if requestCount == 1 {
            tradingPairs.remove(tradingPair)
            requestsForTradingPair.removeValue(forKey: tradingPair)
            log.debug("Removed tradingPair '\(tradingPair.name)' from TickerDaemon.")
        } else {
            requestsForTradingPair[tradingPair] = requestCount - 1
            log.debug("Updated requests (\(requestCount - 1)) for tradingPair '\(tradingPair.name)'.")
        }
        
        if tradingPairs.count == 0 {
            stopUpdateTimer()
        }
    }
    
//    class func addToken(_ token: Token) {
//        guard let tradingPair = TradingPair.getTradingPair(a: token, b: PortfolioManager.shared.baseCurrency) else {
//            return
//        }
//
//        var tokens = storedTokens
//
//        if !storedTokens.contains(token) {
//            UserDefaults.standard.set(tokens.insert(token), forKey: "tokens")
//        }
//        if var storedTokens = UserDefaults.standard.value(forKey: "tokens") as? [String], !storedTokens.contains(token.code) {
//            UserDefaults.standard.set(storedTokens.append(token.code), forKey: "tokens")
//            UserDefaults.standard.synchronize()
//        } else {
//            UserDefaults.standard.set([token], forKey: "tokens")
//            UserDefaults.standard.synchronize()
//        }
//
//        addTradingPair(tradingPair)
//    }
    
//    class func loadStoredTokens() -> Set<Token> {
//        return UserDefaults.standard.value(forKey: "tokens") as? Set<Token> ?? Set()
//    }
    
    /// returns current price for specified trading pair
    class func getCurrentPrice(for tradingPair: TradingPair) -> Double? {
        return currentPriceForTradingPair[tradingPair]
    }
    
    class func reset() {
        stopUpdateTimer()
        tradingPairs = Set<TradingPair>()
        requestsForTradingPair = [TradingPair: Int]()
        log.debug("Reset TickerDaemon.")
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
        log.debug("Started updateTimer for TickerDaemon with \(updateIntervall) second intervall.")
    }
    
    @objc class func stopUpdateTimer() {
        guard updateTimer != nil else {
            // no timer set
            return
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
        log.debug("Stopped updateTimer for TickerDaemon.")
    }
    
    // MARK: - Private Class Methods
    /// updates current price for specified trading pair, notifies delegate of change
    private class func updatePrice(for tradingPair: TradingPair) {
        TickerConnector.fetchCurrentPrice(for: tradingPair, completion: { result in
            switch result {
            case .success(let currentPrice):
                self.currentPriceForTradingPair[tradingPair] = currentPrice.value
                log.verbose("Updated current price for tradingPair '\(tradingPair.name)': \(currentPrice.value)")
                delegate?.didUpdateCurrentPrice(for: tradingPair)
            case .failure(let error):
                log.error("Failed to fetch current price for tradingPair '\(tradingPair.name)': \(error)")
            }
        })
    }
    
}