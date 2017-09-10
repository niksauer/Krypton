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
    
    // MARK: - Public Properties
    let baseCurrency = Currency.Fiat.EUR
    
    var delegate: PortfolioManagerDelegate?
    
    var currentExchangeValue: Double? {
        var currentExchangeValue = 0.0
        for portfolio in portfolios {
            if let portfolioValue = portfolio.currentExchangeValue {
                currentExchangeValue = currentExchangeValue + portfolioValue
            } else {
                return nil
            }
        }
        return currentExchangeValue
    }
    
    var absoluteReturn: Double? {
        var absoluteReturn = 0.0
        for portfolio in portfolios {
            if let portfolioAbsoluteReturn = portfolio.absoluteReturn {
                absoluteReturn = absoluteReturn + portfolioAbsoluteReturn
            } else {
                return nil
            }
        }
        return absoluteReturn
    }
    
    var selectedAddresses: [Address] {
        var selectedAddresses = [Address]()
        for portfolio in selectedPortfolios {
            selectedAddresses.append(contentsOf: portfolio.storedAddresses)
        }
        return selectedAddresses
    }
    
    // MARK: - Private Properties
    private var portfolios = [Portfolio]()
    
    private var selectedPortfolios: [Portfolio] {
        var selectedPortfolios = [Portfolio]()
        for portfolio in portfolios {
            if portfolio.isSelected {
                selectedPortfolios.append(portfolio)
            }
        }
        return selectedPortfolios
    }
    
    private var defaultPortfolio: Portfolio? {
        return portfolios.first(where: { $0.isDefault })
    }
    
    // MARK: - Initialization
    /// loads and updates all stored addresses, request continious ticker price updates
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
    
    // MARK: - Public Methods
    /// returns relative, i.e. percentage, return compared to specified date
    func relativeReturn(since date: Date) -> Double? {
        guard !date.isFuture else {
            return nil
        }
        
        if date.isToday {
            return 0.0
        }
        
        guard let currentExchangeValue = currentExchangeValue, let comparisonExchangeValue = exchangeValue(on: date) else {
            return nil
        }
        
        let difference = currentExchangeValue - comparisonExchangeValue
        return difference / comparisonExchangeValue * 100
    }

    func absoluteReturnHistory(since date: Date) -> [(date: Date, value: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var returnHistory: [(Date, Double)] = []
        
        for (portfolioNumber, portfolio) in portfolios.enumerated() {
            for address in portfolio.storedAddresses {
                if let absoluteReturnHistory = address.absolutReturnHistory(since: date) {
                    if portfolioNumber == 0 {
                        for (date, absoluteReturn) in absoluteReturnHistory {
                            returnHistory.append((date, absoluteReturn))
                        }
                    } else {
                        returnHistory = zip(returnHistory, absoluteReturnHistory).map() { ($0.0, $0.1 + $1.1) }
                    }
                } else {
                    return nil
                }
            }
        }
        
        return returnHistory
    }
    
    func exchangeValue(on date: Date) -> Double? {
        var exchangeValue = 0.0
        for portfolio in selectedPortfolios {
            for address in portfolio.storedAddresses {
                if let addressExchangeValue = address.exchangeValue(on: date) {
                    exchangeValue = exchangeValue + addressExchangeValue
                } else {
                    return nil
                }
            }
        }
        return exchangeValue
    }
    
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
    
    // MARK: - Portfolio Delegate
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

protocol PortfolioManagerDelegate {
    func didUpdatePortfolioManager()
}
