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
//    0x173BAF5C0f1ff25D18b4448C20ff209adC7cc220
//    0x1f4aEDc00572634Bc83A9da8B90617a175476690
    
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
            storedPortfolios = try loadPortfolios()
            print("Loaded \(storedPortfolios.count) portfolio(s) from Core Data.")
            
            if storedPortfolios.count == 0 {
                do {
                    let portfolio = try addPortfolio(alias: "Portfolio 1", baseCurrency: baseCurrency)
                    try portfolio.setIsDefault(true)
                    print("Created and saved empty default portfolio.")
                } catch {
                    print("Failed to create default portfolio.")
                    throw error
                }
            }
            
            for portfolio in storedPortfolios {
                portfolio.delegate = self
                
                for address in portfolio.storedAddresses {
                    print("\(address.identifier!): \(address.balance), \(address.transactions!.count) transaction(s)")
                }
            }
            
            prepareTickerWatchlist()
            updatePortfolios()
        } catch {
            print("Failed to initialize portfolio manager: \(error)")
        }
    }
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in portfolio
    var delegate: PortfolioManagerDelegate?
    
    /// fiat currency used to calculate exchange values of all stored portfolios
    private(set) public var baseCurrency: Currency = {
        if let storedBaseCurrencyCode = UserDefaults.standard.value(forKey: "baseCurrency") as? String, let storedBaseCurrency = CurrencyManager.getCurrency(from: storedBaseCurrencyCode) {
            return storedBaseCurrency
        } else {
            let standardBaseCurrency = Fiat.EUR
            UserDefaults.standard.setValue(standardBaseCurrency.rawValue, forKey: "baseCurrency")
            UserDefaults.standard.synchronize()
            return standardBaseCurrency
        }
    }()

    /// returns all stored portfolios
    private(set) public var storedPortfolios = [Portfolio]()
    
    /// returns default portfolio used to add addresses
    var defaultPortfolio: Portfolio? {
        assert(storedPortfolios.filter({ $0.isDefault }).count > 0, "PortfolioManager.defaultPortfolio -- Database Inconsistency")
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
    
    var storedTradingPairs: Set<TradingPair> {
        return Set(storedAddresses.map { $0.tradingPair })
    }
    
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
    
    private func prepareTickerWatchlist() {
        TickerWatchlist.reset()
        
        for tradingPair in storedTradingPairs {
            TickerWatchlist.addTradingPair(tradingPair)
        }
    }

    // MARK: - Public Methods
    /// returns alias for specified address string
    func getAlias(for addressString: String) -> String? {
        if let alias = storedAddresses.first(where: { $0.identifier == addressString })?.alias, !alias.isEmpty {
            return alias
        } else {
            return nil
        }
    }
    
    func setBaseCurrency(_ currency: Currency) throws {
        guard currency.code != baseCurrency.code else {
            return
        }
        
        do {
            for portfolio in storedPortfolios {
                try portfolio.setBaseCurrency(currency)
            }
            
            UserDefaults.standard.setValue(currency.code, forKey: "baseCurrency")
            UserDefaults.standard.synchronize()
            baseCurrency = currency
            print("Updated base currency of PortfolioManager to \(currency.code).")
            
            prepareTickerWatchlist()
            delegate?.didUpdatePortfolioManager()
        } catch {
            throw error
        }
    }
    
    // MARK: Management
    /// creates, saves and adds portfolio with specified base currency
    func addPortfolio(alias: String?, baseCurrency: Currency) throws -> Portfolio {
        do {
            let context = AppDelegate.viewContext
            let portfolio = Portfolio.createPortfolio(alias: alias, baseCurrency: baseCurrency, in: context)
            try context.save()
            portfolio.delegate = self
            storedPortfolios.append(portfolio)
            delegate?.didUpdatePortfolioManager()
            return portfolio
        } catch {
            throw error
        }
    }
    
    func removePortfolio(_ portfolio: Portfolio) throws {
        do {
            storedPortfolios.remove(at: storedPortfolios.index(of: portfolio)!)
            let context = AppDelegate.viewContext
            context.delete(portfolio)
            try context.save()
            print("Removed portfolio from Core Data.")
            
            prepareTickerWatchlist()
            delegate?.didUpdatePortfolioManager()
        } catch {
            throw error
        }
    }
    
    func updatePortfolios() {
        for portfolio in storedPortfolios {
            portfolio.update()
        }
    }
    
    func save() throws -> Bool  {
        let context = AppDelegate.viewContext
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                throw error
            }
        } else {
            return false
        }
    }
    
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
        
        for storedPortfolio in storedPortfolios {
            if storedPortfolio != portfolio, storedPortfolio.isDefault {
                storedPortfolio.isDefault = false
            }
        }
        
        do {
            try AppDelegate.viewContext.save()
            delegate?.didUpdatePortfolioManager()
        } catch {
            do {
                try portfolio.setIsDefault(false)
            } catch {
                print("Failed to reverse new default portfolio.")
            }
        }
    }
    
    func didUpdateAlias(for portfolio: Portfolio) {
        delegate?.didUpdatePortfolioManager()
    }
    
    func didUpdateBaseCurrency(for portfolio: Portfolio) {
        delegate?.didUpdatePortfolioManager()
    }
    
    func didAddAddress(to portfolio: Portfolio, address: Address) {
        TickerWatchlist.addTradingPair(address.tradingPair)
        delegate?.didUpdatePortfolioManager()
    }
    
    func didRemoveAddress(from portfolio: Portfolio, tradingPair: TradingPair) {
        TickerWatchlist.removeTradingPair(tradingPair)
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

        try? context.save()
    }
    
    private func deleteAddresses() {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        
        if let addresses = try? context.fetch(request) {
            for address in addresses {
                context.delete(address)
            }
        }
        
        try? context.save()
    }
    
    private func deleteTransactions() {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        if let transactions = try? context.fetch(request) {
            for tx in transactions {
                context.delete(tx)
            }
        }
        
        try? context.save()
    }
    
    private func deletePriceHistory() {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        
        if let prices = try? context.fetch(request) {
            for price in prices {
                context.delete(price)
            }
        }
        
        try? context.save()
    }

}
