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
    
//    0xAA2F9BFAA9Ec168847216357b0856d776F34881f
//    0xB15E9Ca894b6134Ac7C22B70b20Fd30De87451B2
//    0x173BAF5C0f1ff25D18b4448C20ff209adC7cc220
//    0x1f4aEDc00572634Bc83A9da8B90617a175476690
    
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
            portfolios = try loadPortfolios()
            print("Loaded \(portfolios.count) portfolio(s) from Core Data.")
            
            if portfolios.count == 0 {
                do {
                    let portfolio = try addPortfolio(baseCurrency: baseCurrency, alias: "Default Portfolio")
                    portfolio.isDefault = true
                    
                    try AppDelegate.viewContext.save()
                    print("Created and saved empty default portfolio.")
                } catch {
                    print("Failed to create default portfolio.")
                    throw error
                }
            }
            
            for portfolio in portfolios {
                portfolio.delegate = self
                portfolio.update()
                
                for address in portfolio.storedAddresses {
                    print("\(address.address!): \(address.balance), \(address.transactions!.count) transaction(s)")
                    TickerWatchlist.addTradingPair(address.tradingPair)
                }
            }
        } catch {
            print("Failed to load portfolios: \(error)")
        }
    }
    
    // MARK: - Private Properties
    /// returns all stored portfolios
    private var portfolios = [Portfolio]()
    
    /// returns default portfolio used to add addresses
    var defaultPortfolio: Portfolio? {
        return portfolios.first(where: { $0.isDefault })
    }
    
    /// returns all addresses associated with stored portfolios
    private var storedAddresses: [Address]? {
        var storedAddresses = [Address]()
        for portfolio in portfolios {
            storedAddresses.append(contentsOf: portfolio.storedAddresses)
        }
        return storedAddresses
    }
    
    // MARK: - Public Properties
    /// fiat currency used to calculate exchange values of all stored portfolios
    let baseCurrency = Currency.Fiat.EUR
    
    /// delegate who gets notified of changes in portfolio
    var delegate: PortfolioManagerDelegate?
    
    /// returns all addresses stored in selected portfolios
    var selectedAddresses: [Address] {
        var selectedAddresses = [Address]()
        for portfolio in portfolios {
            selectedAddresses.append(contentsOf: portfolio.selectedAddresses)
        }
        return selectedAddresses
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

    // MARK: - Public Methods
    /// returns alias for specified address string
    func alias(for addressString: String) -> String? {
        return storedAddresses?.first(where: { $0.address == addressString })?.alias
    }
    
    /// creates address from specfied string with specified crypto unit, adds it to default portfolio
    /// creates address from specfied string with specified crypto unit, add it to specified portfolio
    func addAddress(_ addressString: String, unit: Currency.Crypto, alias: String?, to portfolio: Portfolio) throws {
        do {
            let context = AppDelegate.viewContext
            let address = try Address.createAddress(addressString, unit: unit, alias: alias, in: context)
            portfolio.addAddress(address)
            
            try context.save()
            TickerWatchlist.addTradingPair(address.tradingPair)
        } catch {
            throw error
        }
    }
    
    /// creates, saves and adds portfolio with specified base currency
    func addPortfolio(baseCurrency: Currency.Fiat, alias: String?) throws -> Portfolio {
        do {
            let context = AppDelegate.viewContext
            let portfolio = Portfolio.createPortfolio(baseCurrency: baseCurrency, in: context)
            portfolio.alias = alias
            
            try context.save()
            portfolio.delegate = self
            portfolios.append(portfolio)
            
            return portfolio
        } catch {
            throw error
        }
    }
    
    func getPortfolios() -> [Portfolio] {
        return portfolios
    }
    
    func save() -> Bool {
        let context = AppDelegate.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Saved changes to Portfolio Manager.")
                delegate?.didUpdatePortfolioManager()
                return true
            } catch {
                print("Error saving changes to Portfolio Manager: \(error)")
                return false
            }
        } else {
            return true
        }
    }
    
    // MARK: Finance
    /// returns the current exchange value of all selected addresses
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
    
    /// returns absolute profit of selected addresses compared to specified date
    /// returns the absolute profit generated from all selected addresses
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
            if let absoluteProfitHistory = address.getAbsoluteProfitHistory(for: type, since: date) {
                if index == 0 {
                    for (date, absoluteProfit) in absoluteProfitHistory {
                        profitHistory.append((date, absoluteProfit))
                    }
                } else {
                    profitHistory = zip(profitHistory, absoluteProfitHistory).map() { ($0.0, $0.1 + $1.1) }
                }
            } else {
                return nil
            }
            
        }
        
        return profitHistory
    }
    
    // MARK: - Portfolio Delegate
    /// notifies delegate of changes in portfolio
    func didUpdatePortfolio() {
        delegate?.didUpdatePortfolioManager()
    }
    
    // MARK: - Experimental
    private func deleteCoreDate() {
        deletePortfolios()
        deleteAddresses()
        deleteTransactions()
        deletePriceHistory()
    }
    
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
