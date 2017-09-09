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
    class func createPortfolio(baseCurrency: Currency.Fiat, in context: NSManagedObjectContext) -> Portfolio {
        let portfolio = Portfolio(context: context)
        portfolio.baseCurrency = baseCurrency.rawValue
        return portfolio
    }
    
    // MARK: - Public Properties
    /// delegate who gets notified of wallet changes
    var delegate: PortfolioDelegate?
    
    var storedAddresses: [Address] {
        return Array(addresses!) as! [Address]
    }
    
    /// returns the current summed exchange value of all addresses
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

    // MARK: - Public Methods
    /// returns summed absolute return history of all addresses since specified date, nil if date is today or in the future
    func absoluteReturnHistory(since date: Date) -> [(date: Date, value: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var returnHistory: [(Date, Double)] = []
        
        for (index, address) in storedAddresses.enumerated() {
            if let absoluteReturnHistory = address.absolutReturnHistory(since: date) {
                if index == 0 {
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
        
        return returnHistory
    }
    
    /// returns summed exchange value of all addresses on speicfied date, nil if date is today or in the future
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
    
    /// updates all addresses stored in wallet by updating transaction history, price history and balance
    /// updates its balance, transaction history, price history and requests continious ticker updates for its trading pair
    func update() {
        let context = AppDelegate.viewContext
        
        for address in storedAddresses {
            address.updateBalance(in: context)
            address.updateTransactionHistory(in: context, completion: address.updatePriceHistory)
        }
    }

    /// adds address to wallet, which is its delegate
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
    
    func didUpdateUserExchangeValue(for transaction: Transaction) {
        delegate?.didUpdatePortfolio()
    }
    
    func didUpdateTransactionHistory(for address: Address) {
        delegate?.didUpdatePortfolio()
    }

}

protocol PortfolioDelegate {
    func didUpdatePortfolio()
}

