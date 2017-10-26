//
//  BlockchainWatchlist.swift
//  Krypton
//
//  Created by Niklas Sauer on 26.10.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

protocol BlockchainWatchlistDelegate {
    func didUpdateBlockCount(for blockchain: Blockchain)
}

final class BlockchainWatchlist {
    
    // MARK: - Public Properties
    static var delegate: BlockchainWatchlistDelegate?
    
    // MARK: - Private Properties
    private static var updateTimer: Timer?
    
    private static var updateIntervall: TimeInterval = 60
    
    private static var blockchains = Set<Blockchain>()
    
    private static var blockCountForBlockchain = [Blockchain: UInt64]()
    
    private static var requestsForBlockchain = [Blockchain: Int]()
    
    // MARK: - Public Class Methods
    class func addBlockchain(_ blockchain: Blockchain) {
        if !blockchains.contains(blockchain) {
            blockchains.insert(blockchain)
            updateBlockCount(for: blockchain)
            log.debug("Added blockchain'\(blockchain.rawValue)' to BlockchainWatchlist.")
        }
        
        if blockchains.count == 1 {
            startUpdateTimer()
        }
        
        if let requestCount = requestsForBlockchain[blockchain] {
            log.debug("Updated requests (\(requestCount)) for blockchain '\(blockchain.rawValue)'.")
            requestsForBlockchain[blockchain] = requestCount + 1
        } else {
            requestsForBlockchain[blockchain] = 1
        }
    }
    
    class func removeBlockchain(_ blockchain: Blockchain) {
        guard let requestCount = requestsForBlockchain[blockchain], requestCount > 0 else {
            return
        }
        
        blockchains.remove(blockchain)
        requestsForBlockchain[blockchain] = requestCount - 1
        log.debug("Removed blockchain '\(blockchain.rawValue)' from BlockchainWatchlist.")
    }
    
    class func getBlockCount(for blockchain: Blockchain) -> UInt64? {
        return blockCountForBlockchain[blockchain]
    }
    
    class func reset() {
        stopUpdateTimer()
        blockchains = Set<Blockchain>()
        requestsForBlockchain = [Blockchain: Int]()
        log.debug("Reset BlockchainWatchlist.")
    }
    
    @objc class func startUpdateTimer() {
        guard updateTimer == nil else {
            // timer already running
            return
        }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateIntervall, repeats: true, block: { _ in
            for blockchain in blockchains {
                updateBlockCount(for: blockchain)
            }
        })
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.setObserver(self, selector: #selector(stopUpdateTimer), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.setObserver(self, selector: #selector(startUpdateTimer), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        log.debug("Started updateTimer for BlockchainWatchlist with interval \(updateIntervall) seconds.")
    }
    
    @objc class func stopUpdateTimer() {
        guard updateTimer != nil else {
            // no timer set
            return
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
        log.debug("Stopped updateTimer for BlockchainWatchlist.")
    }
    
    // MARK: - Private Class Methods
    private class func updateBlockCount(for blockchain: Blockchain) {
        BlockchainConnector.fetchBlockCount(for: blockchain) { result in
            switch result {
            case .success(let blockCount):
                self.blockCountForBlockchain[blockchain] = blockCount
                log.verbose("Updated blockCount for blockchain '\(blockchain.rawValue)': \(blockCount)")
                delegate?.didUpdateBlockCount(for: blockchain)
            case .failure(let error):
                log.error("Failed to fetch blockCount for blockchain '\(blockchain.rawValue)': \(error)")
            }
        }
    }
    
}
