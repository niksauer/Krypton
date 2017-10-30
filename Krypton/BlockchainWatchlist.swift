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
    private static var updateTimerForBlockchain = [Blockchain: Timer]()
    
    private static var updateIntervallForBlockchain: [Blockchain: TimeInterval] = [
        .XBT: 600,
        .ETH: 60
    ]
    
    private static var blockchains = Set<Blockchain>()
    
    private static var requestsForBlockchain = [Blockchain: Int]()
    
    private static var blockCountForBlockchain = [Blockchain: UInt64]()

    // MARK: - Public Class Methods
    class func addBlockchain(_ blockchain: Blockchain) {
        if !blockchains.contains(blockchain) {
            blockchains.insert(blockchain)
            updateBlockCount(for: blockchain)
            log.debug("Added blockchain '\(blockchain.rawValue)' to BlockchainWatchlist.")
        }
    
        if let requestCount = requestsForBlockchain[blockchain] {
            log.debug("Updated requests (\(requestCount + 1)) for blockchain '\(blockchain.rawValue)'.")
            requestsForBlockchain[blockchain] = requestCount + 1
        } else {
            requestsForBlockchain[blockchain] = 1
        }
        
        if blockchains.count == 1 {
            startUpdateTimer()
        }
    }
    
    class func removeBlockchain(_ blockchain: Blockchain) {
        guard let requestCount = requestsForBlockchain[blockchain] else {
            return
        }
        
        if requestCount == 1 {
            blockchains.remove(blockchain)
            requestsForBlockchain.removeValue(forKey: blockchain)
            log.debug("Removed blockchain '\(blockchain.rawValue)' from BlockchainWatchlist.")
        } else {
            requestsForBlockchain[blockchain] = requestCount - 1
            log.debug("Updated requests (\(requestCount - 1)) for blockchain '\(blockchain.rawValue)'.")
        }
        
        if blockchains.count == 0 {
            stopUpdateTimer()
        }
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
        for blockchain in blockchains {
            guard updateTimerForBlockchain[blockchain] == nil, let updateIntervall = updateIntervallForBlockchain[blockchain] else {
                // timer already running
                continue
            }
            
            updateTimerForBlockchain[blockchain] = Timer.scheduledTimer(withTimeInterval: updateIntervall, repeats: true, block: { _ in
                updateBlockCount(for: blockchain)
            })
            
            log.debug("Started updateTimer for blockchain '\(blockchain.rawValue)' with \(updateIntervall) second intervall.")
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.setObserver(self, selector: #selector(stopUpdateTimer), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.setObserver(self, selector: #selector(startUpdateTimer), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc class func stopUpdateTimer() {
        for (blockchain, updateTimer) in updateTimerForBlockchain {
            updateTimer.invalidate()
            updateTimerForBlockchain.removeValue(forKey: blockchain)
            log.debug("Stopped updateTimer for blockchain '\(blockchain.rawValue)'.")
        }
    }
    
    // MARK: - Private Class Methods
    private class func updateBlockCount(for blockchain: Blockchain) {
        BlockchainConnector.fetchBlockCount(for: blockchain) { result in
            switch result {
            case .success(let blockCount):
                self.blockCountForBlockchain[blockchain] = blockCount
                log.verbose("Updated block count for blockchain '\(blockchain.rawValue)': \(blockCount)")
                delegate?.didUpdateBlockCount(for: blockchain)
            case .failure(let error):
                log.error("Failed to fetch block count for blockchain '\(blockchain.rawValue)': \(error)")
            }
        }
    }
    
}
