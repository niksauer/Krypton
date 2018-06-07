//
//  BlockchainDaemon.swift
//  Krypton
//
//  Created by Niklas Sauer on 26.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

protocol BlockchainDaemonDelegate: class {
    func blockchainDaemon(_ blockchainDaemon: BlockchainDaemon, didUpdateBlockCountForBlockchain blockchain: Blockchain)
}

final class BlockchainDaemon {
    
    // MARK: - Private Properties
    private var updateTimerForBlockchain = [Blockchain: Timer]()
    
    private var updateIntervallForBlockchain: [Blockchain: TimeInterval] = [
        .BTC: 600,
        .ETH: 60
    ]
    
    private var blockchains = Set<Blockchain>()
    
    private var requestsForBlockchain = [Blockchain: Int]()
    
    private var blockCountForBlockchain = [Blockchain: UInt64]()
    
    // MARK: - Public Properties
    weak var delegate: BlockchainDaemonDelegate?
    
    // MARK: - Private Methods
    @objc private func startUpdateTimer() {
        for blockchain in blockchains {
            guard updateTimerForBlockchain[blockchain] == nil, let updateIntervall = updateIntervallForBlockchain[blockchain] else {
                // timer already running
                continue
            }
            
            updateTimerForBlockchain[blockchain] = Timer.scheduledTimer(withTimeInterval: updateIntervall, repeats: true, block: { _ in
                self.updateBlockCount(for: blockchain)
            })
            
            log.debug("Started timer for blockchain '\(blockchain.rawValue)' with \(updateIntervall) second intervall.")
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.setObserver(self, selector: #selector(stopUpdateTimer), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.setObserver(self, selector: #selector(startUpdateTimer), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc private func stopUpdateTimer() {
        for (blockchain, updateTimer) in updateTimerForBlockchain {
            updateTimer.invalidate()
            updateTimerForBlockchain.removeValue(forKey: blockchain)
            log.debug("Stopped timer for blockchain '\(blockchain.rawValue)'.")
        }
    }
    
    private func updateBlockCount(for blockchain: Blockchain) {
        BlockchainConnector.fetchBlockCount(for: blockchain) { result in
            switch result {
            case .success(let blockCount):
                self.blockCountForBlockchain[blockchain] = blockCount
                log.verbose("Updated block count for blockchain '\(blockchain.rawValue)': \(blockCount)")
                self.delegate?.blockchainDaemon(self, didUpdateBlockCountForBlockchain: blockchain)
            case .failure(let error):
                log.error("Failed to fetch block count for blockchain '\(blockchain.rawValue)': \(error)")
            }
        }
    }
    
    // MARK: - Public Methods
    func addBlockchain(_ blockchain: Blockchain) {
        if !blockchains.contains(blockchain) {
            blockchains.insert(blockchain)
            updateBlockCount(for: blockchain)
            log.debug("Added blockchain '\(blockchain.rawValue)' to BlockchainDaemon.")
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
    
    func removeBlockchain(_ blockchain: Blockchain) {
        guard let requestCount = requestsForBlockchain[blockchain] else {
            return
        }
        
        if requestCount == 1 {
            blockchains.remove(blockchain)
            requestsForBlockchain.removeValue(forKey: blockchain)
            log.debug("Removed blockchain '\(blockchain.rawValue)' from BlockchainDaemon.")
        } else {
            requestsForBlockchain[blockchain] = requestCount - 1
            log.debug("Updated requests (\(requestCount - 1)) for blockchain '\(blockchain.rawValue)'.")
        }
        
        if blockchains.count == 0 {
            stopUpdateTimer()
        }
    }
    
    func getBlockCount(for blockchain: Blockchain) -> UInt64? {
        return blockCountForBlockchain[blockchain]
    }
    
    func reset() {
        stopUpdateTimer()
        blockchains = Set<Blockchain>()
        requestsForBlockchain = [Blockchain: Int]()
        log.debug("Reset BlockchainDaemon.")
    }
    
}
