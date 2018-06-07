//
//  PortfolioManager.swift
//  Krypton
//
//  Created by Niklas Sauer on 05.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

protocol PortfolioManagerDelegate {
    func portfolioManagerDidReceivePortfolioUpdate(_ portfolioManager: PortfolioManager)
    func portfolioManagerDidChangeQuoteCurrency(_ portfolioManager: PortfolioManager)
    func portfolioManagerDidRemovePortfolio(_ portfolioManager: PortfolioManager)
    
    func portfolioManager(_ portfolioManager: PortfolioManager, didNoticeNewAddress address: Address)
    func portfolioManager(_ portfolioManager: PortfolioManager, didNoticeAddressRemovalFromPortfolio portfolio: Portfolio, currencyPair: CurrencyPair, blockchain: Blockchain)
    func portfolioManager(_ portfolioManager: PortfolioManager, didAddCurrency currency: Currency)
    func portfolioManager(_ portfolioManager: PortfolioManager, didRemoveCurrency currency: Currency)
    func portfolioManager(_ portfolioManager: PortfolioManager, didReceiveExchangeRateHistoryUpdateRequestForAddress address: Address)
    func portfolioManager(_ portfolioManager: PortfolioManager, didReceiveTokenExchangeRateHistoryUpdateRequestForAddress tokenAddress: TokenAddress)
}

final class PortfolioManager: PortfolioDelegate {
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext
    private let currencyManager: CurrencyManager
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in portfolio
    var delegate: PortfolioManagerDelegate?
    
    /// fiat currency used to calculate exchange values of all stored portfolios
    private(set) public lazy var quoteCurrency: Currency = {
        return getQuoteCurrency()
    }()
    
    /// returns all stored portfolios
    private(set) public var storedPortfolios = [Portfolio]()
    
    /// returns default portfolio used to add addresses
    var defaultPortfolio: Portfolio? {
        return storedPortfolios.first { $0.isDefault }
    }
    
    /// returns all addresses associated with stored portfolios
    var storedAddresses: [Address] {
        return storedPortfolios.flatMap { $0.storedAddresses }
    }
    
    /// returns all addresses stored in selected portfolios
    var selectedAddresses: [Address] {
        return storedAddresses.filter { $0.isSelected }
    }
    
    var storedTokens: [Token] {
        return (storedAddresses.filter({ $0 is TokenAddress }) as! [TokenAddress]).flatMap { $0.storedTokens }
    }
    
    var storedBlockchains: Set<Blockchain> {
        return Set(storedAddresses.map { $0.blockchain })
    }
    
    var requiredCurrencyPairs: Set<CurrencyPair> {
        return Set(storedAddresses.map { $0.currencyPair } + storedTokens.map { $0.currencyPair })
    }
    
    private(set) public var manualCurrencies = [Currency]()
    
    // MARK: - Initialization
    /// loads all available portfolios, sets itself as their delegate,
    /// updates all stored addresses, requests continious ticker price updates for their trading pars
    init(context: NSManagedObjectContext, currencyManager: CurrencyManager) throws {
        self.context = context
        self.currencyManager = currencyManager
        
//        deletePortfolios()
//        deleteExchangeRateHistory()
        
        do {
            storedPortfolios = try loadPortfolios()
            let multiple = storedPortfolios.count >= 2 || storedPortfolios.count == 0
            log.info("Loaded \(storedPortfolios.count) portfolio\(multiple ? "s" : "") from CoreData.")
        } catch {
            log.error("Failed to load portfolios from CoreData: \(error)")
            throw error
        }
        
        if storedPortfolios.count == 0 {
            do {
                let quoteCurrency = getQuoteCurrency()
                let portfolio = try addPortfolio(alias: "Personal", quoteCurrency: quoteCurrency)
                try portfolio.setIsDefault(true)
                log.info("Created empty default portfolio '\(portfolio.alias!)'.")
            } catch {
                log.error("Failed to create default portfolio.")
                throw error
            }
        }
        
        for portfolio in storedPortfolios {
            portfolio.delegate = self
            
            for address in portfolio.storedAddresses {
                let mulitple = (address.storedTransactions.count >= 2) || (address.storedTransactions.count == 0)
                log.verbose("\(address.identifier!): \(address.balance) \(address.blockchain.code), \(address.storedTransactions.count) transaction\(mulitple ? "s" : "").")
            }
        }
        
        manualCurrencies = loadManualCurrencies()
    }
    
    // MARK: - Private Methods
    /// loads and returns all addresses stored in Core Data
    private func loadPortfolios() throws -> [Portfolio] {
        let request: NSFetchRequest<Portfolio> = Portfolio.fetchRequest()
    
        do {
            return try context.fetch(request)
        } catch {
            throw error
        }
    }
    
    private func loadManualCurrencies() -> [Currency] {
        if let currencyCodes = UserDefaults.standard.value(forKey: "manualCurrencies") as? [String] {
            return currencyCodes.map({ currencyManager.getCurrency(from: $0) }).compactMap { $0 }
        } else {
            return Array()
        }
    }
    
    private func saveManualCurrencies() {
        let currencyCodes = manualCurrencies.map { $0.code }
        UserDefaults.standard.setValue(currencyCodes, forKey: "manualCurrencies")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Public Methods
    /// returns alias for specified address string
    func getAlias(for addressString: String) -> String {
        if let alias = storedAddresses.first(where: { $0.identifier?.lowercased() == addressString.lowercased() })?.alias, !alias.isEmpty {
            return alias
        } else {
            return addressString
        }
    }
    
    func getQuoteCurrency() -> Currency {
        if let storedQuoteCurrencyCode = UserDefaults.standard.value(forKey: "quoteCurrency") as? String, let storedQuoteCurrency = currencyManager.getCurrency(from: storedQuoteCurrencyCode) {
            log.debug("Loaded base currency '\(storedQuoteCurrency)' from UserDefaults.")
            return storedQuoteCurrency
        } else {
            let standardQuoteCurrency = Fiat.EUR
            UserDefaults.standard.setValue(standardQuoteCurrency.rawValue, forKey: "quoteCurrency")
            UserDefaults.standard.synchronize()
            log.debug("Could not load base currency from UserDefaults. Set '\(standardQuoteCurrency)' as default.")
            return standardQuoteCurrency
        }
    }
    
    func setQuoteCurrency(_ currency: Currency) throws {
        let currentQuoteCurrency = getQuoteCurrency()
        
        guard currency.code != currentQuoteCurrency.code else {
            return
        }
        
        do {
            for portfolio in storedPortfolios {
                try portfolio.setQuoteCurrency(currency)
            }
            
            UserDefaults.standard.setValue(currency.code, forKey: "quoteCurrency")
            UserDefaults.standard.synchronize()
            quoteCurrency = currency
            log.debug("Updated base currency (\(currency.code)) of PortfolioManager.")
            
            delegate?.portfolioManagerDidChangeQuoteCurrency(self)
        } catch {
            log.error("Failed to update base currency of PortfolioManager: \(error)")
            throw error
        }
    }
    
    func update(completion: (() -> Void)?) {
        for (index, portfolio) in storedPortfolios.enumerated() {
            var updateCompletion: (() -> Void)? = nil
            
            if index == storedPortfolios.count-1 {
                updateCompletion = completion
            }
            
            portfolio.update(completion: updateCompletion)
        }
    }
    
    // MARK: Management
    /// creates, saves and adds portfolio with specified base currency
    func addPortfolio(alias: String, quoteCurrency: Currency) throws -> Portfolio {
        do {
            let portfolio = Portfolio.createPortfolio(alias: alias, quoteCurrency: quoteCurrency, in: context)
            try context.save()
            portfolio.delegate = self
            storedPortfolios.append(portfolio)
            log.info("Created portfolio '\(alias)' with base currency '\(quoteCurrency)'.")
            delegate?.portfolioManagerDidReceivePortfolioUpdate(self)
            return portfolio
        } catch {
            log.error("Failed to create portfolio: \(error)")
            throw error
        }
    }
    
    func removePortfolio(_ portfolio: Portfolio) throws {
        do {
            let alias = portfolio.alias!
            storedPortfolios.remove(at: storedPortfolios.index(of: portfolio)!)
            context.delete(portfolio)
            try context.save()
            log.info("Deleted portfolio '\(alias)'.")
            delegate?.portfolioManagerDidRemovePortfolio(self)
        } catch {
            log.error("Failed to delete portfolio: \(error)")
            throw error
        }
    }
    
    func addCurrency(_ currency: Currency) {
        guard !manualCurrencies.contains(where: { $0.isEqual(to: currency) }) else {
            return
        }

        manualCurrencies.append(currency)
        log.debug("Manually added currency '\(currency.code)' to PortfolioManager.")
        saveManualCurrencies()
        delegate?.portfolioManager(self, didAddCurrency: currency)
    }

    func removeCurrency(_ currency: Currency) {
        guard let index = manualCurrencies.index(where: { $0.isEqual(to: currency) }) else {
            return
        }
        
        manualCurrencies.remove(at: index)
        log.debug("Removed manually added currency '\(currency.code)' from PortfolioManager.")
        saveManualCurrencies()
        delegate?.portfolioManager(self, didRemoveCurrency: currency)
    }
    
    func saveChanges() throws -> Bool  {
        if context.hasChanges {
            do {
                try context.save()
                log.debug("Saved changes made to CoreData.")
                return true
            } catch {
                log.debug("Failed to save changes made to CoreData.")
                throw error
            }
        } else {
            return false
        }
    }
    
    func discardChanges() {
        log.debug("Discarded all unsaved changes made to CoreData.")
        context.rollback()
    }
    
    // MARK: - Portfolio Delegate
    func portfolioDidUpdateAlias(_ portfolio: Portfolio) {
        delegate?.portfolioManagerDidReceivePortfolioUpdate(self)
    }
    
    func portfolioDidUpdateIsDefault(_ portfolio: Portfolio) {
        guard portfolio.isDefault == true else {
            return
        }
        
        var count = 0
        
        for storedPortfolio in storedPortfolios {
            if storedPortfolio != portfolio, storedPortfolio.isDefault {
                storedPortfolio.isDefault = false
                count = count + 1
            }
        }
        
        do {
            try context.save()
            
            if count > 0 {
                let multiple = (count >= 2) || (count == 0)
                log.debug("Unset \(count) previous default portfolio\(multiple ? "s" : "").")
            }
            
            delegate?.portfolioManagerDidReceivePortfolioUpdate(self)
        } catch {
            log.error("Failed to unset previous default portfolio: \(error)")
            
            do {
                try portfolio.setIsDefault(false)
            } catch {
                log.error("Failed to reverse new default portfolio: \(error)")
            }
        }
    }
    
    func portfolioDidUpdateQuoteCurrency(_ portfolio: Portfolio) {
        delegate?.portfolioManagerDidReceivePortfolioUpdate(self)
    }
    
    func portfolio(_ portfolio: Portfolio, didAddAddress address: Address) {
        delegate?.portfolioManager(self, didNoticeNewAddress: address)
    }
    
    func portfolio(_ portfolio: Portfolio, didRemoveAddressWithCurrencyPair currencyPair: CurrencyPair, blockchain: Blockchain) {
        delegate?.portfolioManager(self, didNoticeAddressRemovalFromPortfolio: portfolio, currencyPair: currencyPair, blockchain: blockchain)
    }
    
    func portfolio(_ portfolio: Portfolio, didNoticePortfolioChangeForAddress address: Address) {
        delegate?.portfolioManagerDidReceivePortfolioUpdate(self)
    }
    
    func portfolio(_ portfolio: Portfolio, didNoticeUpdateForAddress address: Address) {
        delegate?.portfolioManagerDidReceivePortfolioUpdate(self)
    }
    
    func portfolio(_ portfolio: Portfolio, didReceiveExchangeRateHistoryUpdateRequestForAddress address: Address) {
        delegate?.portfolioManager(self, didReceiveExchangeRateHistoryUpdateRequestForAddress: address)
    }
    
    func portfolio(_ portfolio: Portfolio, didReceiveTokenExchangeRateHistoryUpdateRequestForAddress tokenAddress: TokenAddress) {
        delegate?.portfolioManager(self, didReceiveTokenExchangeRateHistoryUpdateRequestForAddress: tokenAddress)
    }
    
    // MARK: - Experimental
    private func deletePortfolios() {
        let request: NSFetchRequest<Portfolio> = Portfolio.fetchRequest()
        
        if let portfolios = try? context.fetch(request) {
            for portfolio in portfolios {
                context.delete(portfolio)
            }
        }

        do {
            try context.save()
            log.info("Deleted all portfolios, addresses and transactions from CoreData.")
        } catch {
            log.error("Failed to delete all portfolios from CoreData: \(error)")
        }
    }
    
    private func deleteExchangeRateHistory() {
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        
        if let history = try? context.fetch(request) {
            for exchangeRate in history {
                context.delete(exchangeRate)
            }
        }
        
        do {
            try context.save()
            log.info("Deleted all exchange rates from CoreData.")
        } catch {
            log.error("Failed to delete all exchange rates from CoreData: \(error)")
        }
        
    }

}

//    ETH Wallet
//    0xAA2F9BFAA9Ec168847216357b0856d776F34881f
//    0xB15E9Ca894b6134Ac7C22B70b20Fd30De87451B2

//    ETH Ledger
//    0x273c1144e0531D9c5762f7F1569e600b827Aff4A

//    BTC
//    1eCjtYU5Fzmjs7P1iHGeYj6Tn86YdEmnY
//    3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC
