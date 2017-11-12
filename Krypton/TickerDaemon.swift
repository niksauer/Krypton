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
    func didUpdateCurrentPrice(for currencyPair: CurrencyPair)
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
    private static var currencyPairs = Set<CurrencyPair>()
    
    /// dictionary mapping trading pairs to their most current price
    private static var currentRateForCurrencyPair = [CurrencyPair: Double]()
    
    private static var requestsForCurrencyPair = [CurrencyPair: Int]()
    
    // MARK: - Public Class Methods
    /// adds trading pair and fetches current price if it has not already been added to watchlist, starts update timer
    class func addCurrencyPair(_ currencyPair: CurrencyPair) {
        if !currencyPairs.contains(currencyPair) {
            currencyPairs.insert(currencyPair)
            updatePrice(for: currencyPair)
            log.debug("Added currencyPair '\(currencyPair.name)' to TickerDaemon.")
        }
    
        if let requestCount = requestsForCurrencyPair[currencyPair] {
            requestsForCurrencyPair[currencyPair] = requestCount + 1
            log.debug("Updated requests (\(requestCount + 1)) for currencyPair '\(currencyPair.name)'.")
        } else {
            requestsForCurrencyPair[currencyPair] = 1
        }
        
        if currencyPairs.count == 1 {
            startUpdateTimer()
        }
    }
    
    class func removeCurrencyPair(_ currencyPair: CurrencyPair) {
        guard let requestCount = requestsForCurrencyPair[currencyPair] else {
            return
        }
        
        if requestCount == 1 {
            currencyPairs.remove(currencyPair)
            requestsForCurrencyPair.removeValue(forKey: currencyPair)
            log.debug("Removed currencyPair '\(currencyPair.name)' from TickerDaemon.")
        } else {
            requestsForCurrencyPair[currencyPair] = requestCount - 1
            log.debug("Updated requests (\(requestCount - 1)) for currencyPair '\(currencyPair.name)'.")
        }
        
        if currencyPairs.count == 0 {
            stopUpdateTimer()
        }
    }
    
//    class func addToken(_ token: Token) {
//        guard let currencyPair = CurrencyPair.getCurrencyPair(a: token, b: PortfolioManager.shared.quoteCurrency) else {
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
//        addCurrencyPair(currencyPair)
//    }
    
//    class func loadStoredTokens() -> Set<Token> {
//        return UserDefaults.standard.value(forKey: "tokens") as? Set<Token> ?? Set()
//    }
    
    /// returns current price for specified trading pair
    class func getCurrentPrice(for currencyPair: CurrencyPair) -> Double? {
        return currentRateForCurrencyPair[currencyPair]
    }
    
    class func reset() {
        stopUpdateTimer()
        currencyPairs = Set<CurrencyPair>()
        requestsForCurrencyPair = [CurrencyPair: Int]()
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
            for currencyPair in currencyPairs {
                updatePrice(for: currencyPair)
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
    private class func updatePrice(for currencyPair: CurrencyPair) {
        TickerConnector.fetchCurrentPrice(for: currencyPair, completion: { result in
            switch result {
            case .success(let currentRate):
                self.currentRateForCurrencyPair[currencyPair] = currentRate.value
                log.verbose("Updated current price for currencyPair '\(currencyPair.name)': \(currentRate.value)")
                delegate?.didUpdateCurrentPrice(for: currencyPair)
            case .failure(let error):
                log.error("Failed to fetch current price for currencyPair '\(currencyPair.name)': \(error)")
            }
        })
    }
    
}
