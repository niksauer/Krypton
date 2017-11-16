//
//  PortfolioManager.swift
//  Krypton
//
//  Created by Niklas Sauer on 05.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

protocol PortfolioManagerDelegate {
    func didUpdatePortfolioManager()
}

final class PortfolioManager: PortfolioDelegate {
    
//    ETH Wallet
//    0xAA2F9BFAA9Ec168847216357b0856d776F34881f
//    0xB15E9Ca894b6134Ac7C22B70b20Fd30De87451B2
    
//    ETH Ledger
//    0x273c1144e0531D9c5762f7F1569e600b827Aff4A
    
//    BTC
//    1eCjtYU5Fzmjs7P1iHGeYj6Tn86YdEmnY
//    3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC
    
    // MARK: - Singleton
    static let shared = PortfolioManager()
    
    // MARK: - Initialization
    /// loads all available portfolios, sets itself as their delegate,
    /// updates all stored addresses, requests continious ticker price updates for their trading pars
    init() {
//        deletePortfolios()
//        deletePriceHistory()
    
        do {
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
            
            prepareTickerDaemon()
            prepareBlockchainDaemon()
            
            update(completion: nil)
        } catch {
            log.error("Failed to initialize PortfolioManager singleton: \(error)")
        }
    }
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in portfolio
    var delegate: PortfolioManagerDelegate?
    
    /// fiat currency used to calculate exchange values of all stored portfolios
    private(set) public var quoteCurrency: Currency = {
        if let storedQuoteCurrencyCode = UserDefaults.standard.value(forKey: "quoteCurrency") as? String, let storedQuoteCurrency = CurrencyManager.getCurrency(from: storedQuoteCurrencyCode) {
            log.debug("Loaded base currency '\(storedQuoteCurrency)' from UserDefaults.")
            return storedQuoteCurrency
        } else {
            let standardQuoteCurrency = Fiat.EUR
            UserDefaults.standard.setValue(standardQuoteCurrency.rawValue, forKey: "quoteCurrency")
            UserDefaults.standard.synchronize()
            log.debug("Could not load base currency from UserDefaults. Set '\(standardQuoteCurrency)' as default.")
            return standardQuoteCurrency
        }
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
    
    // MARK: - Private Methods
    /// loads and returns all addresses stored in Core Data
    private func loadPortfolios() throws -> [Portfolio] {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Portfolio> = Portfolio.fetchRequest()
    
        do {
            return try context.fetch(request)
        } catch {
            throw error
        }
    }
    
    private func loadManualCurrencies() -> [Currency] {
        if let currencyCodes = UserDefaults.standard.value(forKey: "manualCurrencies") as? [String] {
            return currencyCodes.map({ CurrencyManager.getCurrency(from: $0) }).flatMap { $0 }
        } else {
            return Array()
        }
    }
    
    private func saveManualCurrencies() {
        let currencyCodes = manualCurrencies.map { $0.code }
        UserDefaults.standard.setValue(currencyCodes, forKey: "manualCurrencies")
        UserDefaults.standard.synchronize()
    }
    
    private func prepareTickerDaemon() {
        TickerDaemon.reset()
        
        for currencyPair in requiredCurrencyPairs {
            currencyPair.register()
        }
        
        for currency in manualCurrencies {
            let currencyPair = CurrencyPair(base: currency, quote: quoteCurrency)
            currencyPair.register()
        }
    }
    
    private func prepareBlockchainDaemon() {
        BlockchainDaemon.reset()
        
        for blockchain in storedBlockchains {
            BlockchainDaemon.addBlockchain(blockchain)
        }
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
    
    func setQuoteCurrency(_ currency: Currency) throws {
        guard currency.code != quoteCurrency.code else {
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
            
            prepareTickerDaemon()
            
            delegate?.didUpdatePortfolioManager()
        } catch {
            log.error("Failed to update base currency of PortfolioManager: \(error)")
            throw error
        }
    }
    
    func update(completion: (() -> Void)?) {
        for (index, portfolio) in storedPortfolios.enumerated() {
            if index == storedPortfolios.count-1 {
                portfolio.update(completion: completion)
            } else {
                portfolio.update(completion: nil)
            }
        }
    }
    
    // MARK: Management
    /// creates, saves and adds portfolio with specified base currency
    func addPortfolio(alias: String, quoteCurrency: Currency) throws -> Portfolio {
        do {
            let context = AppDelegate.viewContext
            let portfolio = Portfolio.createPortfolio(alias: alias, quoteCurrency: quoteCurrency, in: context)
            try context.save()
            portfolio.delegate = self
            storedPortfolios.append(portfolio)
            log.info("Created portfolio '\(alias)' with base currency '\(quoteCurrency)'.")
            delegate?.didUpdatePortfolioManager()
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
            let context = AppDelegate.viewContext
            context.delete(portfolio)
            try context.save()
            log.info("Deleted portfolio '\(alias)'.")
            prepareTickerDaemon()
            prepareBlockchainDaemon()
            delegate?.didUpdatePortfolioManager()
        } catch {
            log.error("Failed to delete portfolio: \(error)")
            throw error
        }
    }
    
    func addCurrency(_ currency: Currency) {
        guard !manualCurrencies.contains(where: { $0.isEqual(to: currency) }) else {
            return
        }
    
        let currencyPair = CurrencyPair(base: currency, quote: quoteCurrency)
        currencyPair.register()
        manualCurrencies.append(currency)
        log.debug("Manually added currency '\(currency.code)' to PortfolioManager.")
        saveManualCurrencies()
    }

    func removeCurrency(_ currency: Currency) {
        guard let index = manualCurrencies.index(where: { $0.isEqual(to: currency) }) else {
            return
        }
        
        let currencyPair = CurrencyPair(base: currency, quote: quoteCurrency)
        currencyPair.deregister()
        manualCurrencies.remove(at: index)
        log.debug("Removed manually added currency '\(currency.code)' from PortfolioManager.")
        saveManualCurrencies()
    }
    
    func saveChanges() throws -> Bool  {
        let context = AppDelegate.viewContext
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
        AppDelegate.viewContext.rollback()
    }
    
//    func moveAddress(_ address: Address, to portfolio: Portfolio) throws {
//        do {
//            try address.setQuoteCurrency(portfolio.quoteCurrency)
//            address.portfolio = portfolio
//            try AppDelegate.viewContext.save()
//            log.info("Moved address '\(address.logDescription)' to portfolio '\(portfolio.logDescription)'.")
//        } catch {
//            log.error("Failed to move address '\(address.logDescription)': \(error)")
//        }
//    }
    
    // MARK: Finance
    /// returns exchange value of selected addresses on specified date
    func getExchangeValue(for type: TransactionType, on date: Date) -> Double? {
        var value = 0.0
        
        for address in selectedAddresses {
            if let addressValue = address.getExchangeValue(for: type, on: date)?.value {
                value = value + addressValue
            } else {
                return nil
            }
        }
        
        return value
    }
    
    /// returns the absolute profit generated from all selected addresses in specified timeframe
    func getProfitStats(for type: TransactionType, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        
        for address in selectedAddresses {
            if let profitStats = address.getProfitStats(for: type, timeframe: timeframe) {
                startValue = startValue + profitStats.startValue
                endValue = endValue + profitStats.endValue
            } else {
                return nil
            }
        }
    
        return (startValue, endValue)
    }
    
    /// returns absolute profit history of selected addresses since specified date
    func getAbsoluteProfitHistory(for type: TransactionType, since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for address in selectedAddresses {
            guard let absoluteProfitHistory = address.getAbsoluteProfitHistory(for: type, since: date) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteProfitHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
    // MARK: - Portfolio Delegate
    func didUpdateIsDefault(for portfolio: Portfolio) {
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
            try AppDelegate.viewContext.save()
            
            if count > 0 {
                let multiple = (count >= 2) || (count == 0)
                log.debug("Unset \(count) previous default portfolio\(multiple ? "s" : "").")
            }
            
            delegate?.didUpdatePortfolioManager()
        } catch {
            log.error("Failed to unset previous default portfolio: \(error)")
            
            do {
                try portfolio.setIsDefault(false)
            } catch {
                log.error("Failed to reverse new default portfolio: \(error)")
            }
        }
    }
    
    func didUpdateAlias(for portfolio: Portfolio) {
        delegate?.didUpdatePortfolioManager()
    }
    
    func didUpdateQuoteCurrency(for portfolio: Portfolio) {
        delegate?.didUpdatePortfolioManager()
    }
    
    func didAddAddress(to portfolio: Portfolio, address: Address) {
        TickerDaemon.addCurrencyPair(address.currencyPair)
        BlockchainDaemon.addBlockchain(address.blockchain)
        delegate?.didUpdatePortfolioManager()
    }
    
    func didRemoveAddress(from portfolio: Portfolio, currencyPair: CurrencyPair, blockchain: Blockchain) {
        TickerDaemon.removeCurrencyPair(currencyPair)
        BlockchainDaemon.removeBlockchain(blockchain)
        delegate?.didUpdatePortfolioManager()
    }
    
    func didUpdateProperty(for address: Address, in portfolio: Portfolio) {
        delegate?.didUpdatePortfolioManager()
    }
    
    // MARK: - Experimental
    private func deletePortfolios() {
        let context = AppDelegate.viewContext
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
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<ExchangeRate> = ExchangeRate.fetchRequest()
        
        if let prices = try? context.fetch(request) {
            for price in prices {
                context.delete(price)
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
