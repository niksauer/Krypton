//
//  KryptonDaemon.swift
//  Krypton
//
//  Created by Niklas Sauer on 06.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

protocol KryptonDaemonDelegate: class {
    func kryptonDaemonDidUpdate(_ kryptonDaemon: KryptonDaemon)
}

final class KryptonDaemon: PortfolioManagerDelegate {
    
    // MARK: - Private Properties
    private let portfolioManager: PortfolioManager
    private let tickerDaemom: TickerDaemon
    private let blockchainDaemon: BlockchainDaemon
    private let exchangeRateManager: ExchangeRateManager
    
    // MARK: - Public Properties
    weak var delegate: KryptonDaemonDelegate?
    
    // MARK: - Initialization
    init(portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, blockchainDaemon: BlockchainDaemon, exchangeRateManager: ExchangeRateManager) {
        self.portfolioManager = portfolioManager
        self.tickerDaemom = tickerDaemon
        self.blockchainDaemon = blockchainDaemon
        self.exchangeRateManager = exchangeRateManager
        
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
    func portfolioManagerDidChangeQuoteCurrency(_ portfolioManager: PortfolioManager) {
        prepareTickerDaemon()
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManagerDidReceivePortfolioUpdate(_ portfolioManager: PortfolioManager) {
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManagerDidRemovePortfolio(_ portfolioManager: PortfolioManager) {
        prepareTickerDaemon()
        prepareBlockchainDaemon()
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didNoticeNewAddress address: Address) {
        tickerDaemom.addCurrencyPair(address.currencyPair)
        blockchainDaemon.addBlockchain(address.blockchain)
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didNoticeAddressRemovalFromPortfolio portfolio: Portfolio, currencyPair: CurrencyPair, blockchain: Blockchain) {
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
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didReceiveExchangeRateHistoryUpdateRequestForAddress address: Address) {
        guard let oldestTransaction = address.getOldestTransaction() else {
            return
        }
        
        exchangeRateManager.updateExchangeRateHistory(for: address.currencyPair, since: oldestTransaction.date!, completion: nil)
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didReceiveTokenExchangeRateHistoryUpdateRequestForAddress tokenAddress: TokenAddress) {
        // TODO
    }
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didNoticeNewTokenForAddress address: TokenAddress, token: Token) {
        let currencyPair = CurrencyPair(base: token.storedToken, quote: portfolioManager.quoteCurrency)
        tickerDaemom.addCurrencyPair(currencyPair)
        delegate?.kryptonDaemonDidUpdate(self)
    }
    
}
