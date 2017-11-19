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
    func didUpdateCurrentExchangeRate(for currencyPair: CurrencyPair)
}

final class TickerDaemon {
    
    // MARK: - Public Properties
    /// delegate who is notified of price updates
    static var delegate: TickerDaemonDelegate?
    
    // MARK: - Private Properties
    /// timer used to continioulsy fetch price updates
    private static var updateTimer: Timer?
    
    /// price update interval specified in seconds
    private static var updateIntervall: TimeInterval = 30
    
    /// trading pairs for which continious price updates are retrieved
    private static var currencyPairs = Set<CurrencyPair>()
    
    /// dictionary mapping trading pairs to their most current price
    private static var currentExchangeRateForCurrencyPair = [CurrencyPair: Double]()
    
    private static var requestsForCurrencyPair = [CurrencyPair: Int]()
    
    // MARK: - Public Class Methods
    /// adds trading pair and fetches current price if it has not already been added to watchlist, starts update timer
    class func addCurrencyPair(_ currencyPair: CurrencyPair) {
        if !currencyPairs.contains(currencyPair) {
            currencyPairs.insert(currencyPair)
            updateExchangeRate(for: currencyPair, completion: nil)
            log.debug("Added currency pair '\(currencyPair.name)' to TickerDaemon.")
        }
    
        if let requestCount = requestsForCurrencyPair[currencyPair] {
            requestsForCurrencyPair[currencyPair] = requestCount + 1
            log.debug("Updated requests (\(requestCount + 1)) for currency pair '\(currencyPair.name)'.")
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
            log.debug("Removed currency pair '\(currencyPair.name)' from TickerDaemon.")
        } else {
            requestsForCurrencyPair[currencyPair] = requestCount - 1
            log.debug("Updated requests (\(requestCount - 1)) for currency pair '\(currencyPair.name)'.")
        }
        
        if currencyPairs.count == 0 {
            stopUpdateTimer()
        }
    }
    
    /// returns current price for specified trading pair
    class func getCurrentExchangeRate(for currencyPair: CurrencyPair) -> Double? {
        return currentExchangeRateForCurrencyPair[currencyPair]
    }
    
    class func reset() {
        stopUpdateTimer()
        currencyPairs = Set<CurrencyPair>()
        requestsForCurrencyPair = [CurrencyPair: Int]()
        log.debug("Reset TickerDaemon.")
    }
    
    class func update(completion: (() -> Void)?) {
        for (index, currencyPair) in currencyPairs.enumerated() {
            var updateCompletion: (() -> Void)? = nil
            
            if index == currencyPairs.count-1 {
                updateCompletion = completion
            }
            
            updateExchangeRate(for: currencyPair, completion: updateCompletion)
        }
    }
    
    /// starts unique timer to update current price in specified interval for all stored trading pairs
    /// timer stop if app enters background, starts/continues when becoming active again
    @objc class func startUpdateTimer() {
        guard updateTimer == nil else {
            // timer already running
            return
        }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateIntervall, repeats: true, block: { _ in
            update(completion: nil)
        })
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.setObserver(self, selector: #selector(stopUpdateTimer), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.setObserver(self, selector: #selector(startUpdateTimer), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        log.debug("Started timer for TickerDaemon with \(updateIntervall) second intervall.")
    }
    
    @objc class func stopUpdateTimer() {
        guard updateTimer != nil else {
            // no timer set
            return
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
        log.debug("Stopped timer for TickerDaemon.")
    }
    
    // MARK: - Private Class Methods
    /// updates current price for specified trading pair, notifies delegate of change
    private class func updateExchangeRate(for currencyPair: CurrencyPair, completion: (() -> Void)?) {
        TickerConnector.fetchCurrentExchangeRate(for: currencyPair, completion: { result in
            switch result {
            case .success(let currentExchangeRate):
                self.currentExchangeRateForCurrencyPair[currencyPair] = currentExchangeRate.value
                log.verbose("Updated current exchange rate for currency pair '\(currencyPair.name)': \(currentExchangeRate.value)")
                delegate?.didUpdateCurrentExchangeRate(for: currencyPair)
                completion?()
            case .failure(let error):
                log.error("Failed to fetch current exchange rate for currency pair '\(currencyPair.name)': \(error)")
                completion?()
            }
        })
    }
    
}
