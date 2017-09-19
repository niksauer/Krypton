//
//  Portfolio.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

class Portfolio: NSManagedObject, AddressDelegate {
    
    // MARK: - Public Class Methods
    /// creates and returns portfolio with specified base currency
    class func createPortfolio(baseCurrency: Currency.Fiat, in context: NSManagedObjectContext) -> Portfolio {
        let portfolio = Portfolio(context: context)
        portfolio.baseCurrency = baseCurrency.rawValue
        return portfolio
    }
    
    // MARK: - Initialization
    /// sets itself as delegate of all stored addresses
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        
        for address in storedAddresses {
            address.delegate = self
        }
    }
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in portfolio, i.e., balance, transaction history and all associated transactions' userExchangeValue, isInvestment properties
    var delegate: PortfolioDelegate?
    
    /// returns all addresses associated with portfolio
    var storedAddresses: [Address] {
        return Array(addresses!) as! [Address]
    }
    
    var selectedAddresses: [Address] {
        var selectedAddresses = [Address]()
        for address in storedAddresses {
            if address.isSelected {
                selectedAddresses.append(address)
            }
        }
        return selectedAddresses
    }
    
    // MARK: - Public Methods
    // MARK: Setters
    func setAlias(_ alias: String) throws {
        guard self.alias != alias else {
            return
        }
        
        do {
            self.alias = alias
            try AppDelegate.viewContext.save()
            print("Saved updated alias for portfolio.")
            delegate?.didUpdateAlias(for: self)
        } catch {
            throw error
        }
    }
    
    func setIsDefault(_ state: Bool) throws {
        guard self.isDefault != state else {
            return
        }
        
        do {
            isDefault = state
            try AppDelegate.viewContext.save()
            print("Saved updated is default status for portfolio.")
            delegate?.didUpdateIsDefault(for: self)
        } catch {
            throw error
        }
    }
    
    func setBaseCurrency(_ currency: Currency.Fiat) throws {
        do {
            baseCurrency = currency.rawValue
            try AppDelegate.viewContext.save()
            print("Saved updated base currency for portfolio.")
            delegate?.didUpdateBaseCurrency(for: self)
        } catch {
            throw error
        }
    }

    // MARK: Management
    /// updates all stored addresses by updating their transaction history, price history and balance
    func update() {
        for address in storedAddresses {
            address.updateTransactionHistory() {
                address.updatePriceHistory {
                    address.updateBalance()
                }
            }
        }
    }
    
    /// adds address to portfolio, sets portfolio as its delegate, updates portfolio
    func addAddress(_ addressString: String, unit: Currency.Crypto, alias: String?) throws {
        do {
            let context = AppDelegate.viewContext
            let address = try Address.createAddress(addressString, unit: unit, alias: alias, in: context)
            self.addToAddresses(address)
            try context.save()
            address.delegate = self
            delegate?.didUpdateAddresses(in: self)
            update()
        } catch {
            throw error
        }
    }
    
    func removeAddress(address: Address) throws {
        do {
            let context = AppDelegate.viewContext
            context.delete(address)
            try context.save()
            delegate?.didUpdateAddresses(in: self)
        } catch {
            throw error
        }
    }
    
    // MARK: Finance
    /// returns the current exchange value of all stored addresses
    /// returns exchange value of all stored addresses on speicfied date, nil if date is today or in the future
    func getExchangeValue(for type: TransactionType, on date: Date) -> Double? {
        var value = 0.0
        for address in storedAddresses {
            if let addressValue = address.getExchangeValue(for: type, on: date)?.value {
                value = value + addressValue
            } else {
                return nil
            }
        }
        return value
    }
    
    /// returns the absolute profit generated from all stored addresses
    func getProfitStats(for type: TransactionType, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        
        for address in storedAddresses {
            if let profitStats = address.getProfitStats(for: type, timeframe: timeframe) {
                startValue = startValue + profitStats.startValue
                endValue = endValue + profitStats.endValue
            } else {
                return nil
            }
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute profit history of all stored addresses since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(for type: TransactionType, since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for (index, address) in storedAddresses.enumerated() {
            if let absoluteProfitHistory = address.getAbsoluteProfitHistory(for: type, since: date) {
                if index == 0 {
                    for (date, absoluteReturn) in absoluteProfitHistory {
                        profitHistory.append((date, absoluteReturn))
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
    
    // MARK: - Address Delegate
    /// notifies delegate that balance has changed for specified address
    func didUpdateBalance(for address: Address) {
        delegate?.didUpdateAddresses(in: self)
    }
    
    /// notified delegate that tranasction history has changed for specified address
    func didUpdateTransactionHistory(for address: Address) {
        delegate?.didUpdateAddresses(in: self)
    }
    
    /// notifies delegate that userExchangeValue has been set for specified transaction
    func didUpdateUserExchangeValue(for transaction: Transaction) {
        delegate?.didUpdateAddresses(in: self)
    }
    
    /// notifies delegate that isInvestment property has changed for specified transaction
    func didUpdateIsInvestmentStatus(for transaction: Transaction) {
        delegate?.didUpdateAddresses(in: self)
    }
    
    func didUpdateAlias(for address: Address) {
        delegate?.didUpdateAddresses(in: self)
    }

}

// MARK: - Portfolio Delegate Protocol
protocol PortfolioDelegate {
    func didUpdateAddresses(in portfolio: Portfolio)
    func didUpdateBaseCurrency(for portfolio: Portfolio)
    func didUpdateIsDefault(for portfolio: Portfolio)
    func didUpdateAlias(for portfolio: Portfolio)
}

