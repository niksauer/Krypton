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
    
    /// returns the current exchange value of all stored addresses
    var currentExchangeValue: Double? {
        var exchangeValue = 0.0
        for address in storedAddresses {
            if let addressExchangeValue = address.currentExchangeValue {
                exchangeValue = exchangeValue + addressExchangeValue
            } else {
                return nil
            }
        }
        return exchangeValue
    }

    /// returns the absolute profit generated from all stored addresses
    var absoluteProfit: Double? {
        var absoluteProfit = 0.0
        for address in storedAddresses {
            if let addressAbsoluteProfit = address.absoluteProfit {
                absoluteProfit = absoluteProfit + addressAbsoluteProfit
            } else {
                return nil
            }
        }
        return absoluteProfit
    }
    
    /// returns the total value invested in stored addresses
    var investmentValue: Double? {
        var investmentValue = 0.0
        for address in storedAddresses {
            if let addressInvestmentValue = address.investmentValue {
                investmentValue = investmentValue + addressInvestmentValue
            } else {
                return nil
            }
        }
        return investmentValue
    }
    
    // MARK: - Public Methods
    /// returns absolute profit history of all stored addresses since specified date, nil if date is today or in the future
    func absoluteProfitHistory(since date: Date) -> [(date: Date, value: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for (index, address) in storedAddresses.enumerated() {
            if let absoluteProfitHistory = address.absoluteProfitHistory(since: date) {
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
    
    /// returns exchange value of all stored addresses on speicfied date, nil if date is today or in the future
    func exchangeValue(on date: Date) -> Double? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var exchangeValue = 0.0
        
        for address in storedAddresses {
            if let addressExchangeValue = address.exchangeValue(on: date) {
                exchangeValue = exchangeValue + addressExchangeValue
            } else {
                return nil
            }
        }
        
        return exchangeValue
    }
    
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
    func addAddress(_ address: Address) {
        address.delegate = self
        self.addToAddresses(address)
        update()
    }

    // MARK: - Address Delegate
    /// notifies delegate that balance has changed for specified address
    func didUpdateBalance(for address: Address) {
        delegate?.didUpdatePortfolio()
    }
    
    /// notified delegate that tranasction history has changed for specified address
    func didUpdateTransactionHistory(for address: Address) {
        delegate?.didUpdatePortfolio()
    }
    
    /// notifies delegate that userExchangeValue has been set for specified transaction
    func didUpdateUserExchangeValue(for transaction: Transaction) {
        delegate?.didUpdatePortfolio()
    }
    
    /// notifies delegate that isInvestment property has changed for specified transaction
    func didUpdateIsInvestmentStatus(for transaction: Transaction) {
        delegate?.didUpdatePortfolio()
    }
    
}

// MARK: - Portfolio Delegate Protocol
protocol PortfolioDelegate {
    func didUpdatePortfolio()
}

