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
    private let currencyManager: CurrencyManager
    
    // MARK: - Initialization
    init(exchangeRateManager: ExchangeRateManager, currencyManager: CurrencyManager) {
        self.exchangeRateManager = exchangeRateManager
        self.currencyManager = currencyManager
    }
    
    // MARK: - Public Methods
    // MARK: Transaction
    /// returns exchange value as encountered on execution date according to owners trading pair
    func getExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: transaction.date!, valueType: .total)
    }
    
    /// returns the current exchange value according to owners trading pair
    func getCurrentExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: Date(), valueType: .total)
    }
    
    func getFeeExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: transaction.date!, valueType: .fee)
    }
    
    func getCurrentFeeExchangeValue(for transaction: Transaction) -> Double? {
        return getExchangeValue(for: transaction, on: Date(), valueType: .fee)
    }
    
    func getExchangeValue(for transaction: Transaction, on date: Date, valueType: TransactionValueType) -> Double? {
        guard !date.isFuture else {
            return nil
        }
        
        if transaction.hasUserExchangeValue, date.UTCStart == transaction.date!.UTCStart {
            guard let userExchangeValueQuoteCurrencyCode = transaction.userExchangeValueQuoteCurrencyCode else {
                return nil
            }
            
            guard transaction.owner!.quoteCurrency.code != userExchangeValueQuoteCurrencyCode else {
                return transaction.userExchangeValue
            }
            
            let userExchangeValueQuoteCurrency = currencyManager.getCurrency(from: userExchangeValueQuoteCurrencyCode)!
            let userExchangeValueCurrencyPair = CurrencyPair(base: transaction.owner!.blockchain, quote: userExchangeValueQuoteCurrency)
            let newUserExchangeValueCurrencyPair = transaction.owner!.currencyPair
            
            guard let userExchangeValueRate = exchangeRateManager.getExchangeRate(for: userExchangeValueCurrencyPair, on: transaction.date!), let newUserExchangeValueRate = exchangeRateManager.getExchangeRate(for: newUserExchangeValueCurrencyPair, on: transaction.date!) else {
                return nil
            }
            
            let conversionRate = newUserExchangeValueRate / userExchangeValueRate
            
            return transaction.userExchangeValue * conversionRate
        }
        
        guard let exchangeRate = exchangeRateManager.getExchangeRate(for: transaction.owner!.currencyPair, on: date) else {
            log.warning("Failed to get exchange value for transaction '\(transaction.logDescription)'.")
            return nil
        }
        
        switch valueType {
        case .fee:
            return exchangeRate * transaction.feeAmount
        case .total:
            return exchangeRate * transaction.totalAmount
        }
    }
    
    /// returns the total absolute profit according to owners trading pair
    func getProfitStats(for transaction: Transaction, timeframe: ProfitTimeframe) -> (startValue: Double, endValue: Double)? {
        let startDate: Date
        let txDate = transaction.date!
        
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
        
        guard let startValue = getExchangeValue(for: transaction, on: startDate, valueType: .total), let endValue = getExchangeValue(for: transaction, on: Date(), valueType: .total) else {
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
        let txDate = transaction.date!.UTCStart
        
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
        guard let baseExchangeValue = getExchangeValue(for: transaction, on: startDate, valueType: .total) else {
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
            } else if let exchangeValue = getExchangeValue(for: transaction, on: date, valueType: .total) {
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
            // token is probaby not listed on exchange
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
    func getExchangeValue(for address: Address, on date: Date, type: TransactionType) -> (balance: Double, value: Double)? {
        guard !date.isFuture, let balance = address.getBalance(on: date, type: type), let exchangeRate = exchangeRateManager.getExchangeRate(for: address.currencyPair, on: date) else {
            return nil
        }
        
        return (balance, exchangeRate * balance)
    }
    
    /// returns total value invested in address
    func getProfitStats(for address: Address, timeframe: ProfitTimeframe, type: TransactionType) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        let transactions = address.getTransactions(type: type)
        
        for transaction in transactions {
            guard let profitStats = getProfitStats(for: transaction, timeframe: timeframe) else {
                return nil
            }
            
            startValue = startValue + profitStats.startValue
            endValue = endValue + profitStats.endValue
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute return history since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(for address: Address, since date: Date, type: TransactionType) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture, address.storedTransactions.count > 0 else {
            return nil
        }
        
        let transactions = address.getTransactions(type: type)
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
    func getTokenExchangeValue(for tokenAddress: TokenAddress, on date: Date) -> Double {
        var value = 0.0
        
        for token in tokenAddress.storedTokens {
            guard let exchangeValue = getExchangeValue(for: token, on: date) else {
                // token probably not listed on exchange yet
                continue
            }
            
            value = value + exchangeValue
        }
        
        return value
    }
    
    // MARK: Portfolio
    func getTotalExchangeValue(for portfolio: Portfolio) -> Double? {
        guard let balanceExchangeValue = getExchangeValue(for: portfolio, on: Date(), type: .all), let tokenExchangeValue = getTokenExchangeValue(for: portfolio, on: Date()) else {
            return nil
        }

        return balanceExchangeValue + tokenExchangeValue
    }
    
    /// returns exchange value of all stored addresses on speicfied date, nil if date is today or in the future
    func getExchangeValue(for portfolio: Portfolio, on date: Date, type: TransactionType) -> Double? {
        var value = 0.0
        
        for address in portfolio.storedAddresses {
            guard let addressValue = getExchangeValue(for: address, on: date, type: type)?.value else {
                return nil
            }
            
            value = value + addressValue
        }
        
        return value
    }
    
    func getTokenExchangeValue(for portfolio: Portfolio, on date: Date) -> Double? {
        let storedTokenAddresses = (portfolio.storedAddresses.filter({ $0 is TokenAddress }) as! [TokenAddress])
        return storedTokenAddresses.reduce(0, { $0 + getTokenExchangeValue(for: $1, on: date)})
    }
    
    /// returns the absolute profit generated from all stored addresses
    func getProfitStats(for portfolio: Portfolio, timeframe: ProfitTimeframe, type: TransactionType) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        
        for address in portfolio.storedAddresses {
            guard let profitStats = getProfitStats(for: address, timeframe: timeframe, type: type) else {
                return nil
            }
            
            startValue = startValue + profitStats.startValue
            endValue = endValue + profitStats.endValue
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute profit history of all stored addresses since specified date, nil if date is today or in the future
    func getAbsoluteProfitHistory(for portfolio: Portfolio, since date: Date, type: TransactionType) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for address in portfolio.storedAddresses {
            guard let absoluteProfitHistory = getAbsoluteProfitHistory(for: address, since: date, type: type) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteProfitHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
    // MARK: Portfolios
    /// returns exchange value of selected addresses on specified date
    func getExchangeValue(for addresses: [Address], on date: Date, type: TransactionType) -> Double? {
        var value = 0.0
        
        for address in addresses {
            guard let addressValue = getExchangeValue(for: address, on: date, type: type)?.value else {
                return nil
            }
            
            value = value + addressValue
        }
        
        return value
    }
    
    /// returns the absolute profit generated from all selected addresses in specified timeframe
    func getProfitStats(for addresses: [Address], timeframe: ProfitTimeframe, type: TransactionType) -> (startValue: Double, endValue: Double)? {
        var startValue = 0.0
        var endValue = 0.0
        
        for address in addresses {
            guard let profitStats = getProfitStats(for: address, timeframe: timeframe, type: type) else {
                return nil
            }
            
            startValue = startValue + profitStats.startValue
            endValue = endValue + profitStats.endValue
        }
        
        return (startValue, endValue)
    }
    
    /// returns absolute profit history of selected addresses since specified date
    func getAbsoluteProfitHistory(for addresses: [Address], since date: Date, type: TransactionType) -> [(date: Date, profit: Double)]? {
        guard !date.isToday, !date.isFuture else {
            return nil
        }
        
        var profitHistory: [(Date, Double)] = []
        
        for address in addresses {
            guard let absoluteProfitHistory = getAbsoluteProfitHistory(for: address, since: date, type: type) else {
                return nil
            }
            
            profitHistory = zip(profitHistory, absoluteProfitHistory).map { ($0.0, $0.1 + $1.1) }
        }
        
        return profitHistory
    }
    
}
