//
//  Portfolio.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

protocol PortfolioDelegate {
    func portfolioDidUpdateAlias(_ portfolio: Portfolio)
    func portfolioDidUpdateIsDefault(_ portfolio: Portfolio)
    func portfolioDidUpdateQuoteCurrency(_ portfolio: Portfolio)
    
    func portfolio(_ portfolio: Portfolio, didAddAddress address: Address)
    func portfolio(_ portfolio: Portfolio, didRemoveAddressWithCurrencyPair currencyPair: CurrencyPair, blockchain: Blockchain)
    func portfolio(_ portfolio: Portfolio, didNoticePortfolioChangeForAddress address: Address)
    func portfolio(_ portfolio: Portfolio, didNoticeUpdateForAddress address: Address)
}

class Portfolio: NSManagedObject, AddressDelegate, TokenAddressDelegate {
    
    // MARK: - Public Class Methods
    /// creates and returns portfolio with specified base currency
    class func createPortfolio(alias: String?, quoteCurrency: Currency, in context: NSManagedObjectContext) -> Portfolio {
        let portfolio = Portfolio(context: context)
        portfolio.alias = alias
        portfolio.quoteCurrencyCode = quoteCurrency.code
        return portfolio
    }
    
    // MARK: - Initialization
    /// sets itself as delegate of all stored addresses
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        
        for address in storedAddresses {
            switch address {
            case let tokenAddress as TokenAddress:
                tokenAddress.tokenDelegate = self
                log.debug("Set portfolio '\(self.logDescription)' as token delegate of address '\(address.identifier!)'.")
                fallthrough
            default:
                address.delegate = self
                log.debug("Set portfolio '\(self.logDescription)' as delegate of address '\(address.identifier!)'.")
            }
        }
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext = CoreDataStack.shared.viewContext
    private let currencyManager = CurrencyManager()
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in portfolio, i.e., balance, transaction history and all associated transactions' userExchangeValue, isInvestment properties
    var delegate: PortfolioDelegate?
    
    private(set) public var quoteCurrency: Currency {
        get {
            return currencyManager.getCurrency(from: quoteCurrencyCode!)!
        }
        set {
            quoteCurrencyCode = newValue.code
        }
    }
    
    /// returns all addresses associated with portfolio
    var storedAddresses: [Address] {
        return Array(addresses!) as! [Address]
    }
    
    var selectedAddresses: [Address] {
        return storedAddresses.filter { $0.isSelected }
    }
    
    var logDescription: String {
        return "\(self.alias!), quoteCurrency: \(self.quoteCurrency.code)"
    }
    
    var totalExchangeValue: Double? {
        guard let balanceExchangeValue = getExchangeValue(for: .all, on: Date()), let tokenExchangeValue = getTokenExchangeValue(on: Date()) else {
            return nil
        }
        
        return balanceExchangeValue + tokenExchangeValue
    }
    
    // MARK: - Public Methods
    func setAlias(_ alias: String) throws {
        guard self.alias != alias else {
            return
        }
        
        do {
            self.alias = alias
            try context.save()
            log.debug("Updated alias (\(alias)) for portfolio '\(self.logDescription)'.")
            delegate?.portfolioDidUpdateAlias(self)
        } catch {
            log.error("Failed to update alias for portfolio '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    func setIsDefault(_ state: Bool) throws {
        guard self.isDefault != state else {
            return
        }
        
        do {
            self.isDefault = state
            try context.save()
            log.debug("Updated isDefault status (\(state)) for portfolio '\(self.logDescription)'.")
            delegate?.portfolioDidUpdateIsDefault(self)
        } catch {
            log.error("Failed to update isDefault status for portfolio '\(self.logDescription)'.")
            throw error
        }
    }
    
    func setQuoteCurrency(_ currency: Currency) throws {
        guard self.quoteCurrency.code != currency.code else {
            return
        }
        
        do {
            self.quoteCurrencyCode = currency.code
            try context.save()
            
            for address in storedAddresses {
                try address.setQuoteCurrency(currency)
            }
            
            self.update(completion: nil)
            log.debug("Updated quote currency (\(currency.code)) for portfolio '\(self.logDescription)'.")
            delegate?.portfolioDidUpdateQuoteCurrency(self)
        } catch {
            log.error("Failed to update quote currency for portfolio '\(self.logDescription).")
            throw error
        }
    }
    
    // MARK: Management
    /// updates all stored addresses by updating their transaction history, price history and balance
    func update(completion: (() -> Void)?) {
        for (index, address) in storedAddresses.enumerated() {
            var updateCompletion: (() -> Void)? = nil
            
            if index == storedAddresses.count-1 {
                updateCompletion = completion
            }
        
            address.update(completion: updateCompletion)
        }
    }
    
    /// adds address to portfolio, sets portfolio as its delegate, updates portfolio
    func addAddress(_ addressString: String, alias: String?, blockchain: Blockchain) throws {
        do {
            let address = try Address.createAddress(addressString, alias: alias, blockchain: blockchain, quoteCurrency: quoteCurrency, in: context)
            self.addToAddresses(address)
            try context.save()
            address.delegate = self
            log.info("Created and added address '\(address.logDescription)' to portfolio '\(self.logDescription)'.")
            delegate?.portfolio(self, didAddAddress: address)
            address.update(completion: nil)
        } catch {
            log.error("Failed to create address '\(addressString)': \(error)")
            throw error
        }
    }
    
    func removeAddress(address: Address) throws {
        do {
            let addressIdentifier = address.identifier!
            let currencyPair = address.currencyPair
            let blockchain = address.blockchain
            context.delete(address)
            try context.save()
            log.info("Removed address '\(addressIdentifier)' from portfolio '\(self.logDescription)'.")
            delegate?.portfolio(self, didRemoveAddressWithCurrencyPair: currencyPair, blockchain: blockchain)
        } catch {
            log.error("Failed to remove address '\(address.identifier!)' from from portfolio '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    // MARK: Finance
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
    
    func getTokenExchangeValue(on date: Date) -> Double? {
        let storedTokens = (storedAddresses.filter({ $0 is TokenAddress }) as! [TokenAddress]).flatMap({ $0.storedTokens })
        var value = 0.0

        for token in storedTokens {
            if let tokenValue = token.getExchangeValue(on: date) {
                value = value + tokenValue
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
        
        for address in storedAddresses {
            guard let absoluteProfitHistory = address.getAbsoluteProfitHistory(for: type, since: date) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteProfitHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
    // MARK: - Address Delegate
    /// notifies delegate that balance has changed for specified address
    func addressDidUpdateBalance(_ address: Address) {
        delegate?.portfolio(self, didNoticeUpdateForAddress: address)
    }
    
    /// notified delegate that tranasction history has changed for specified address
    func addressDidUpdateTransactionHistory(_ address: Address) {
        delegate?.portfolio(self, didNoticeUpdateForAddress: address)
    }
    
    func address(_ address: Address, didNoticeUpdateForTransaction: Transaction) {
        delegate?.portfolio(self, didNoticeUpdateForAddress: address)
    }
    
    func addressDidUpdateAlias(_ address: Address) {
        delegate?.portfolio(self, didNoticeUpdateForAddress: address)
    }
    
    func addressDidUpdateQuoteCurrency(_ address: Address) {
        delegate?.portfolio(self, didNoticeUpdateForAddress: address)
    }
    
    func addressDidUpdatePortfolio(_ address: Address) {
        delegate?.portfolio(self, didNoticePortfolioChangeForAddress: address)
    }
    
    // MARK: - TokenAddress Delegate
    func tokenAddress(_ tokenAddress: TokenAddress, didUpdateBalanceForToken token: Token) {
        delegate?.portfolio(self, didNoticeUpdateForAddress: tokenAddress)
    }
    
}
