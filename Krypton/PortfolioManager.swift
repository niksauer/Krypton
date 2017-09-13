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
    
    /// returns all selected portfolios
    private var selectedPortfolios: [Portfolio] {
        var selectedPortfolios = [Portfolio]()
        for portfolio in portfolios {
            if portfolio.isSelected {
                selectedPortfolios.append(portfolio)
            }
        }
        return selectedPortfolios
    }
    
    /// returns default portfolio used to add addresses
    private var defaultPortfolio: Portfolio? {
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
        for portfolio in selectedPortfolios {
            selectedAddresses.append(contentsOf: portfolio.storedAddresses)
        }
        return selectedAddresses
    }
    
    /// returns the current exchange value of all selected addresses
    var currentExchangeValue: Double? {
        var currentExchangeValue = 0.0
        for address in selectedAddresses {
            if let addressValue = address.currentExchangeValue {
                currentExchangeValue = currentExchangeValue + addressValue
            } else {
                return nil
            }
        }
        return currentExchangeValue
    }
    
    /// returns the absolute profit generated from all selected addresses
    var absoluteProfit: Double? {
        var absoluteProfit = 0.0
        for address in selectedAddresses {
            if let addressAbsoluteProfit = address.absoluteProfit {
                absoluteProfit = absoluteProfit + addressAbsoluteProfit
            } else {
                return nil
            }
        }
        return absoluteProfit
    }
    
    /// returns the total value invested in all selected addresses
    var investmentValue: Double? {
        var investmentValue = 0.0
        for address in selectedAddresses {
            if let addressInvestmentValue = address.investmentValue {
                investmentValue = investmentValue + addressInvestmentValue
            } else {
                return nil
            }
        }
        return investmentValue
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
    /// returns relative profit, i.e., percentage increase, of selected addresses compared to specified date
    func relativeProfit(since date: Date) -> Double? {
        if date.isToday || selectedAddresses.count == 0 {
            return 0.0
        }
        
        guard !date.isFuture, let currentExchangeValue = currentExchangeValue, let comparisonExchangeValue = exchangeValue(on: date) else {
            return nil
        }
        
        let difference = currentExchangeValue - comparisonExchangeValue
        return difference / comparisonExchangeValue * 100
    }
    
    /// returns absolute profit of selected addresses compared to specified date
    func absoluteProfit(since date: Date) -> Double? {
        if date.isToday || selectedAddresses.count == 0 {
            return 0.0
        }
        
        guard !date.isFuture, let currentExchangeValue = currentExchangeValue, let comparisonExchangeValue = exchangeValue(on: date) else {
            return nil
        }
        
        return currentExchangeValue - comparisonExchangeValue
    }

    /// returns absolute profit history of selected addresses since specified date
    func absoluteReturnHistory(since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for (index, address) in selectedAddresses.enumerated() {
            if let absoluteProfitHistory = address.absoluteProfitHistory(since: date) {
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
    
    /// returns exchange value of selected addresses on specified date
    func exchangeValue(on date: Date) -> Double? {
        var exchangeValue = 0.0
        for address in selectedAddresses {
            if let addressExchangeValue = address.exchangeValue(on: date) {
                exchangeValue = exchangeValue + addressExchangeValue
            } else {
                return nil
            }
        }
        return exchangeValue
    }
    

    /// returns alias for specified address string
    func alias(for addressString: String) -> String? {
        return storedAddresses?.first(where: { $0.address == addressString })?.alias
    }
    
    
    /// creates address from specfied string with specified crypto unit, adds it to default portfolio
    func addAddress(_ addressString: String, unit: Currency.Crypto) throws {
        do {
            let context = AppDelegate.viewContext
            var portfolio: Portfolio!
            
            if portfolios.count == 0 {
                do {
                    portfolio = try addPortfolio(baseCurrency: baseCurrency)
                    portfolio.isDefault = true
                } catch {
                    throw error
                }
            } else if let defaultPortfolio = defaultPortfolio {
                portfolio = defaultPortfolio
            }

            let address = try Address.createAddress(addressString, unit: unit, in: context)
            portfolio.addAddress(address)
            
            do {
                if context.hasChanges {
                    try context.save()
                    TickerWatchlist.addTradingPair(address.tradingPair)
                }
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
    
    /// creates address from specfied string with specified crypto unit, add it to specified portfolio
    func addAddress(_ addressString: String, unit: Currency.Crypto, to portfolio: Portfolio) throws {
        do {
            let context = AppDelegate.viewContext
            let address = try Address.createAddress(addressString, unit: unit, in: context)
            portfolio.addAddress(address)
            
            do {
                try context.save()
                TickerWatchlist.addTradingPair(address.tradingPair)
            }
        } catch {
            throw error
        }
    }
    
    /// creates, saves and adds portfolio with specified base currency
    func addPortfolio(baseCurrency: Currency.Fiat) throws -> Portfolio {
        do {
            let context = AppDelegate.viewContext
            let portfolio = Portfolio.createPortfolio(baseCurrency: baseCurrency, in: context)
            
            try context.save()
            portfolio.delegate = self
            portfolios.append(portfolio)
            
            return portfolio
        } catch {
            throw error
        }
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
