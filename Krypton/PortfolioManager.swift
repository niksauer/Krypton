//
//  PortfolioManager.swift
//  Krypton
//
//  Created by Niklas Sauer on 05.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

final class PortfolioManager: PortfolioDelegate {
    
//    ETH
//    0xAA2F9BFAA9Ec168847216357b0856d776F34881f
//    0xB15E9Ca894b6134Ac7C22B70b20Fd30De87451B2
//    0x173BAF5C0f1ff25D18b4448C20ff209adC7cc220
//    0x1f4aEDc00572634Bc83A9da8B90617a175476690
    
//    BTC
//    1eCjtYU5Fzmjs7P1iHGeYj6Tn86YdEmnY
//    3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC
    
    // MARK: - Singleton
    static let shared = PortfolioManager()
    
    // MARK: - Initialization
    /// loads all available portfolios, sets itself as their delegate,
    /// updates all stored addresses, requests continious ticker price updates for their trading pars
    private init() {
//        deletePortfolios()
//        deleteAddresses()
//        deleteTransactions()
//        deletePriceHistory()
        
        do {
            baseCurrency = loadBaseCurrency()
            storedPortfolios = try loadPortfolios()
            print("Loaded \(storedPortfolios.count) portfolio(s) from Core Data.")
            
            if storedPortfolios.count == 0 {
                do {
                    let portfolio = try addPortfolio(baseCurrency: baseCurrency, alias: "Portfolio 1")
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
    
    // MARK: - Private Properties
    /// returns all stored portfolios
    private var storedPortfolios = [Portfolio]()

    /// returns all addresses associated with stored portfolios
    private var storedAddresses: [Address]? {
        var storedAddresses = [Address]()
        for portfolio in storedPortfolios {
            storedAddresses.append(contentsOf: portfolio.storedAddresses)
        }
        return storedAddresses
    }
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in portfolio
    var delegate: PortfolioManagerDelegate?
    
    /// fiat currency used to calculate exchange values of all stored portfolios
    var baseCurrency = Fiat.EUR
    
    /// returns default portfolio used to add addresses
    var defaultPortfolio: Portfolio? {
        return storedPortfolios.first(where: { $0.isDefault })
    }
    
    /// returns all addresses stored in selected portfolios
    var selectedAddresses: [Address] {
        var selectedAddresses = [Address]()
        for portfolio in storedPortfolios {
            selectedAddresses.append(contentsOf: portfolio.selectedAddresses)
        }
        return selectedAddresses
    }
    
    var storedCryptoCurrencies: [Blockchain]? {
        guard storedAddresses != nil else {
            return nil
        }
        
        var cryptoCurrencies = Set<Blockchain>()
        
        for address in storedAddresses! {
            cryptoCurrencies.insert(address.blockchain)
        }
        
        return Array(cryptoCurrencies)
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
    
    private func loadBaseCurrency() -> Fiat {
        if let storedCurrencyString = UserDefaults.standard.value(forKey: "baseCurrency") as? String, let storedBaseCurrency = Fiat(rawValue: storedCurrencyString) {
            return storedBaseCurrency
        } else {
            let standardBaseCurrency = Fiat.EUR
            UserDefaults.standard.setValue(standardBaseCurrency.rawValue, forKey: "baseCurrency")
            UserDefaults.standard.synchronize()
            return standardBaseCurrency
        }
    }
    
    private func prepareTickerWatchlist() {
        TickerWatchlist.reset()
        
        for portfolio in storedPortfolios {
            for address in portfolio.storedAddresses {
                TickerWatchlist.addTradingPair(address.tradingPair)
            }
        }
    }

    // MARK: - Public Methods
    // MARK: Getters
    func getPortfolios() -> [Portfolio] {
        return storedPortfolios
    }
    
    /// returns alias for specified address string
    func getAlias(for addressString: String) -> String? {
        if let alias = storedAddresses?.first(where: { $0.identifier == addressString })?.alias, !alias.isEmpty {
            return alias
        } else {
            return nil
        }
    }
    
    // MARK: Setters
    func setBaseCurrency(_ fiat: Fiat) throws {
        guard fiat != baseCurrency else {
            return
        }
        
        do {
            for portfolio in storedPortfolios {
                try portfolio.setFiat(fiat)
            }
            
            baseCurrency = fiat
            UserDefaults.standard.setValue(fiat.rawValue, forKey: "baseCurrency")
            UserDefaults.standard.synchronize()
            
            updatePortfolios()
            prepareTickerWatchlist()
        } catch {
            throw error
        }
    }
    
    // MARK: Management
    /// creates, saves and adds portfolio with specified base currency
    func addPortfolio(baseCurrency: Fiat, alias: String?) throws -> Portfolio {
        do {
            let context = AppDelegate.viewContext
            let portfolio = Portfolio.createPortfolio(fiat: baseCurrency, alias: alias, in: context)
            let _ = try save()
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
            let _ = try save()
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
        
        for (index, address) in selectedAddresses.enumerated() {
            guard let absoluteProfitHistory = address.getAbsoluteProfitHistory(for: type, since: date) else {
                return nil
            }
            
            if index == 0 {
                for (date, absoluteProfit) in absoluteProfitHistory {
                    profitHistory.append((date, absoluteProfit))
                }
            } else {
                profitHistory = zip(profitHistory, absoluteProfitHistory).map() { ($0.0, $0.1 + $1.1) }
            }
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
            let _ = try save()
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

// MARK: - Portfolio Manager Delegate Protocol
protocol PortfolioManagerDelegate {
    func didUpdatePortfolioManager()
}
