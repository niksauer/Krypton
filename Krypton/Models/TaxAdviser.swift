//
//  taxAdviser.swift
//  Krypton
//
//  Created by Niklas Sauer on 07.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

@objc enum TransactionType: Int {
    case all
    case investment
    case other
}

enum TransactionValueType {
    case fee
    case total
}

enum ProfitTimeframe {
    case allTime
    case sinceDate(Date)
}

struct TaxAdviser {
    
    // MARK: - Private Properties
    private let exchangeRateManager: ExchangeRateManager
    
    // MARK: - Initialization
    init(exchangeRateManager: ExchangeRateManager) {
        self.exchangeRateManager = exchangeRateManager
    }
    
    // MARK: - Public Methods
    // MARK: Transaction
    /// returns exchange value as encountered on execution date according to owners trading pair
    func getExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: transaction.date!, for: .total)
    }
    
    /// returns the current exchange value according to owners trading pair
    func getCurrentExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: Date(), for: .total)
    }
    
    func getFeeExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: transaction.date!, for: .fee)
    }
    
    func getCurrentFeeExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: Date(), for: .fee)
    }
    
    func getExchangeValue(for transaction: Transaction, on date: Date, for type: TransactionValueType) -> Double? {
        guard !date.isFuture else {
            return nil
        }
        
        if date.UTCStart == transaction.date?.UTCStart, transaction.hasUserExchangeValue {
            return transaction.userExchangeValue
        }
        
        guard let exchangeRate = exchangeRateManager.getExchangeRate(for: transaction.owner!.currencyPair, on: date) else {
            log.warning("Failed to get exchange value for transaction '\(transaction.logDescription)'.")
            return nil
        }
        
        switch type {
        case .fee:
            return exchangeRate * transaction.feeAmount
        case .total:
            return exchangeRate * transaction.totalAmount
        }
    }
    
    /// returns the total absolute profit according to owners trading pair
    func getProfitStats(for transaction: Transaction, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        let startDate: Date
        let txDate = transaction.date! as Date
        
        switch timeframe {
        case .allTime:
            startDate = txDate
        case .sinceDate(let date):
            guard !date.isToday, !date.isFuture else {
                return nil
            }
            
            if date < txDate {
                startDate = txDate
            } else {
                startDate = date
            }
        }
        
        guard let startValue = getExchangeValue(for: transaction, on: startDate, for: .total), let endValue = getExchangeValue(for: transaction, on: Date(), for: .total) else {
            return nil
        }
        
        if transaction.isOutbound {
            return (startValue * -1, endValue * -1)
        } else {
            return (startValue, endValue)
        }
    }
    
    /// returns absolute profit history since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(for transaction: Transaction, since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        let sinceDate = date.UTCStart
        let txDate = (transaction.date! as Date).UTCStart
        
        var absoluteProfitHistory: [(Date, Double)] = []
        
        // fill response with 0s if requested date preceeds transaction
        // calculate start date of absolute return history -> either specified date or transaction start
        let startDate: Date
        
        if sinceDate < txDate {
            // calculate number of days between sinceDate and txDance, including txDate ??
            let daysUntilStart = Calendar.current.dateComponents([.day], from: sinceDate, to: txDate).day!
            
            for daysPassed in 0..<daysUntilStart {
                let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: sinceDate)!
                let absoluteProfit = 0.0
                absoluteProfitHistory.append((date, absoluteProfit))
            }
            
            startDate = Calendar.current.date(byAdding: .day, value: daysUntilStart, to: sinceDate)!
        } else {
            startDate = sinceDate
        }
        
        // get transaction value at start date
        guard let baseExchangeValue = getExchangeValue(for: transaction, on: startDate, for: .total) else {
            return nil
        }
        
        // calculate number of days between startDate and today, including today
        // calculate return history for that timeframe accordingly
        let daysMissing = Calendar.current.dateComponents([.day], from: startDate, to: Date().UTCStart).day!
        
        for daysPassed in 0...daysMissing {
            let date = Calendar.current.date(byAdding: .day, value: daysPassed, to: startDate)!
            var absoluteProfit: Double
            
            if daysPassed == 0 {
                // return for startDate
                absoluteProfit = 0.0
            } else if let exchangeValue = getExchangeValue(for: transaction, on: date, for: .total) {
                // return for any day between startDate and today, including today
                absoluteProfit = exchangeValue - baseExchangeValue
            } else {
                // error retrieving ExchangeRate
                return nil
            }
            
            // outbound transaction = loss
            if transaction.isOutbound {
                absoluteProfit = absoluteProfit * -1
            }
            
            absoluteProfitHistory.append((date, absoluteProfit))
        }
        
        return absoluteProfitHistory
    }
    
    // MARK: Token
    func getCurrentExchangeValue(for token: Token) -> Double? {
        return getExchangeValue(for: token, on: Date())
    }
    
    func getExchangeValue(for token: Token, on date: Date) -> Double? {
        guard !date.isFuture else {
            return nil
        }
        
        guard let exchangeRate = exchangeRateManager.getExchangeRate(for: token.currencyPair, on: date) else {
            log.warning("Failed to get exchange value for token '\(token.logDescription)'.")
            return nil
        }
        
        return exchangeRate * token.balance
    }
    
    func getProfitStats(for token: Token, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        preconditionFailure("This method must be overridden")
    }
    
    func getAbsoluteProfitHistory(for token: Token, since date: Date) -> [(date: Date, profit: Double)]? {
        preconditionFailure("This method must be overridden")
    }
    
    // MARK: Address
    /// returns balance for specified transaction type on specified date
    func getExchangeValue(for address: Address, for type: TransactionType, on date: Date) -> (balance: Double, value: Double)? {
        guard !date.isFuture, let balance = address.getBalance(for: type, on: date), let exchangeRate = exchangeRateManager.getExchangeRate(for: address.currencyPair, on: date) else {
            return nil
        }
        
        return (balance, exchangeRate * balance)
    }
    
    /// returns total value invested in address
    func getProfitStats(for address: Address, for type: TransactionType, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        let transactions = address.getTransactions(of: type)
        
        for transaction in transactions {
            if let profitStats = getProfitStats(for: transaction, timeframe: timeframe) {
                startValue = startValue + profitStats.startValue
                endValue = endValue + profitStats.endValue
            } else {
                return nil
            }
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute return history since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(for address: Address, for type: TransactionType, since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture, address.storedTransactions.count > 0 else {
            return nil
        }
        
        let transactions = address.getTransactions(of: type)
        var profitHistory: [(Date, Double)] = []
        
        for transaction in transactions {
            guard let absoluteReturnHistory = getAbsoluteProfitHistory(for: transaction, since: date) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteReturnHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
    // MARK: TokenAddress
    func getTokenExchangeValue(for tokenAddress: TokenAddress, on date: Date) -> Double? {
        var value = 0.0
        
        for token in tokenAddress.storedTokens {
            if let exchangeValue = getExchangeValue(for: token, on: date) {
                value = value + exchangeValue
            } else {
                return nil
            }
        }
        
        return value
    }
    
    // MARK: Portfolio
    func getTotalExchangeValue(for portfolio: Portfolio) -> Double? {
        guard let balanceExchangeValue = getExchangeValue(for: portfolio, for: .all, on: Date()), let tokenExchangeValue = getTokenExchangeValue(for: portfolio, on: Date()) else {
            return nil
        }
        
        return balanceExchangeValue + tokenExchangeValue
    }
    
    /// returns exchange value of all stored addresses on speicfied date, nil if date is today or in the future
    func getExchangeValue(for portfolio: Portfolio, for type: TransactionType, on date: Date) -> Double? {
        var value = 0.0
        
        for address in portfolio.storedAddresses {
            if let addressValue = getExchangeValue(for: address, for: type, on: date)?.value {
                value = value + addressValue
            } else {
                return nil
            }
        }
        
        return value
    }
    
    func getTokenExchangeValue(for portfolio: Portfolio, on date: Date) -> Double? {
        let storedTokens = (portfolio.storedAddresses.filter({ $0 is TokenAddress }) as! [TokenAddress]).flatMap({ $0.storedTokens })
        var value = 0.0
        
        for token in storedTokens {
            if let tokenValue = getExchangeValue(for: token, on: date) {
                value = value + tokenValue
            } else {
                return nil
            }
        }
        
        return value
    }
    
    /// returns the absolute profit generated from all stored addresses
    func getProfitStats(for portfolio: Portfolio, for type: TransactionType, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        
        for address in portfolio.storedAddresses {
            if let profitStats = getProfitStats(for: address, for: type, timeframe: timeframe) {
                startValue = startValue + profitStats.startValue
                endValue = endValue + profitStats.endValue
            } else {
                return nil
            }
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute profit history of all stored addresses since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(for portfolio: Portfolio, for type: TransactionType, since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for address in portfolio.storedAddresses {
            guard let absoluteProfitHistory = getAbsoluteProfitHistory(for: address, for: type, since: date) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteProfitHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
    // MARK: Portfolios
    /// returns exchange value of selected addresses on specified date
    func getExchangeValue(for addresses: [Address], for type: TransactionType, on date: Date) -> Double? {
        var value = 0.0
        
        for address in addresses {
            if let addressValue = getExchangeValue(for: address, for: type, on: date)?.value {
                value = value + addressValue
            } else {
                return nil
            }
        }
        
        return value
    }
    
    /// returns the absolute profit generated from all selected addresses in specified timeframe
    func getProfitStats(for addresses: [Address], for type: TransactionType, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        
        for address in addresses {
            if let profitStats = getProfitStats(for: address, for: type, timeframe: timeframe) {
                startValue = startValue + profitStats.startValue
                endValue = endValue + profitStats.endValue
            } else {
                return nil
            }
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute profit history of selected addresses since specified date
    func getAbsoluteProfitHistory(for addresses: [Address], for type: TransactionType, since date: Date) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for address in addresses {
            guard let absoluteProfitHistory = getAbsoluteProfitHistory(for: address, for: type, since: date) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteProfitHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
}