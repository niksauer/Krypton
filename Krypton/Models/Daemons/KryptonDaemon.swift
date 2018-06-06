//
//  KryptonService.swift
//  Krypton
//
//  Created by Niklas Sauer on 06.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

protocol KryptonDaemonDelegate {
    func kryptonDaemonDidUpdate(_ kryptonService: KryptonDaemon)
}

final class KryptonDaemon: PortfolioManagerDelegate {
    
    // MARK: - Public Properties
    private let portfolioManager: PortfolioManager
    private let tickerDaemom: TickerDaemon
    private let blockchainDaemon: BlockchainDaemon
    
    var delegate: KryptonDaemonDelegate?
    
    // MARK: - Initialization
    init(portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, blockchainDaemon: BlockchainDaemon) {
        self.portfolioManager = portfolioManager
        self.tickerDaemom = tickerDaemon
        self.blockchainDaemon = blockchainDaemon
        
        portfolioManager.delegate = self
        prepareTickerDaemon()
        prepareBlockchainDaemon()
        portfolioManager.update(completion: nil)
    }
    
    // MARK: - Private Methods
    private func prepareTickerDaemon() {
        tickerDaemom.reset()
        
        for currencyPair in portfolioManager.requiredCurrencyPairs {
            tickerDaemom.addCurrencyPair(currencyPair)
        }
        
        for currency in portfolioManager.manualCurrencies {
            let currencyPair = CurrencyPair(base: currency, quote: portfolioManager.quoteCurrency)
            tickerDaemom.addCurrencyPair(currencyPair)
        }
    }
    
    private func prepareBlockchainDaemon() {
        blockchainDaemon.reset()
        
        for blockchain in portfolioManager.storedBlockchains {
            blockchainDaemon.addBlockchain(blockchain)
        }
    }
    
    // MARK: - PortfolioManager Delegate
    func portfolioManager(_ portfolioManager: PortfolioManager, didNoticeNewAddress address: Address) {
        tickerDaemom.addCurrencyPair(address.currencyPair)
        blockchainDaemon.addBlockchain(address.blockchain)
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didNoticeAddressRemovalFromPortfolio portfolio: Portfolio, currencyPair: CurrencyPair, blockchain: Blockchain) {
        tickerDaemom.removeCurrencyPair(currencyPair)
        blockchainDaemon.removeBlockchain(blockchain)
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManagerDidChangeQuoteCurrency(_ portfolioManager: PortfolioManager) {
        prepareTickerDaemon()
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didRemovePortfolio portfolio: Portfolio) {
        prepareTickerDaemon()
        prepareBlockchainDaemon()
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didAddCurrency currency: Currency) {
        let currencyPair = CurrencyPair(base: currency, quote: portfolioManager.quoteCurrency)
        tickerDaemom.addCurrencyPair(currencyPair)
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didRemoveCurrency currency: Currency) {
        let currencyPair = CurrencyPair(base: currency, quote: portfolioManager.quoteCurrency)
        tickerDaemom.removeCurrencyPair(currencyPair)
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManagerDidUpdatePortfolioDetails(_ portfolioManager: PortfolioManager) {
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
}
