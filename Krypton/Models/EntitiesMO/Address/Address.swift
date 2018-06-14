//
//  Address.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

enum AddressError: Error {
    case duplicate
    case invalidFormat
}

protocol AddressDelegate {
    func addressDidUpdateTransactionHistory(_ address: Address)
    func addressDidUpdateBalance(_ address: Address)
    func addressDidUpdateAlias(_ address: Address)
    func addressDidUpdateQuoteCurrency(_ address: Address)
    func addressDidUpdatePortfolio(_ address: Address)
    func addressDidRequestExchangeRateHistoryUpdate(_ address: Address)
    
    func address(_ address: Address, didNoticeUpdateForTransaction: Transaction)
}

class Address: NSManagedObject, TransactionDelegate, Reportable {
    
    // MARK: - Public Class Methods
    /// creates and returns address if non-existent in database, throws otherwise
    class func createAddress(_ addressString: String, alias: String?, blockchain: Blockchain, quoteCurrency: Currency, in context: NSManagedObjectContext) throws -> Address {
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@", addressString)
        
        let matches = try context.fetch(request)
        
        if matches.count > 0 {
            assert(matches.count >= 1, "Address.createAddress -- Database Inconsistency")
            throw AddressError.duplicate
        }
        
        let address: Address
        
        switch blockchain {
        case .Ethereum:
            address = EthereumAddress(context: context)
        case .Bitcoin:
            address = BitcoinAddress(context: context)
        }
    
        address.identifier = addressString
        
        guard address.isValidAddress() else {
            context.delete(address)
            throw AddressError.invalidFormat
        }
        
        address.alias = alias.nilIfEmpty?.trimmingCharacters(in: .whitespacesAndNewlines)
        address.quoteCurrencyCode = quoteCurrency.code
        
        return address
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext = CoreDataStack.shared.viewContext
    private let currencyManager: CurrencyManager = CurrencyManager()
    private let blockExplorer: BlockExplorer = BlockchainService()
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in balance, transaction history and all associated transactions' userExchangeValue, isInvestment properties
    var delegate: AddressDelegate?
    
    var blockchain: Blockchain {
        get {
            return Blockchain(rawValue: blockchainRaw!)!
        }
    }
    
    private(set) var quoteCurrency: Currency {
        get {
            return currencyManager.getCurrency(from: quoteCurrencyCode!)!
        }
        set {
            quoteCurrencyCode = newValue.code
        }
    }
    
    /// returns trading pair constructed from owner's quoteCurrency + address' cryptoCurrency
    var currencyPair: CurrencyPair {
        return CurrencyPair(base: blockchain, quote: quoteCurrency)
    }
    
    /// returns all transaction associated with address
    var storedTransactions: [Transaction] {
        return Array(transactions!) as! [Transaction]
    }
    
    // MARK: - Reportable
    var logDescription: String {
        return "\(self.identifier!), alias: \(self.alias ?? "None")"
    }
    
    // MARK: - Initialization
    override func awakeFromFetch() {
        super.awakeFromFetch()
        delegate = portfolio
        log.debug("Set portfolio '\(portfolio!.logDescription)' as delegate of address '\(logDescription)'.")
    }
    
    // MARK: - Public Methods
    /// returns the oldest transaction associated with address
    final func getOldestTransaction() -> Transaction? {
        return storedTransactions.min(by: { $0.date! < $1.date! })
    }
    
    final func getTransactions(type: TransactionType) -> [Transaction] {
        switch type {
        case .investment:
            return storedTransactions.filter { $0.isInvestment }
        case .other:
            return storedTransactions.filter { !$0.isInvestment }
        case .all:
            return storedTransactions
        }
    }
    
    final func setAlias(_ alias: String?) throws {
        guard self.alias != alias else {
            return
        }
        
        do {
            self.alias = alias.nilIfEmpty?.trimmingCharacters(in: .whitespacesAndNewlines)
            try context.save()
            log.debug("Updated alias for address '\(logDescription)'.")
            delegate?.addressDidUpdateAlias(self)
        } catch {
            log.error("Failed to update alias for address '\(logDescription)': \(error)")
            throw error
        }
    }
    
    final func setQuoteCurrency(_ currency: Currency) throws {
        guard !self.quoteCurrency.isEqual(to: currency) else {
            return
        }
        
        do {
            self.quoteCurrency = currency
            try context.save()
            log.debug("Updated quote currency (\(currency)) for address '\(logDescription)'.")
            delegate?.addressDidUpdateQuoteCurrency(self)
            delegate?.addressDidRequestExchangeRateHistoryUpdate(self)
        } catch {
            log.error("Failed to update quote currency for address '\(logDescription)': \(error)")
            throw error
        }
    }
    
    final func setPortfolio(_ portfolio: Portfolio) throws {
        guard self.portfolio != portfolio else {
            return
        }
        
        do {
            self.portfolio = portfolio
            try context.save()
            log.debug("Moved address '\(logDescription)' to portfolio '\(portfolio.logDescription)'.")
            delegate?.addressDidUpdatePortfolio(self)
            delegate = portfolio
        } catch {
            log.error("Failed to move address '\(logDescription)' to portfolio '\(portfolio.logDescription)': \(error)")
            throw error
        }
    }

    // MARK: Management
    func update(completion: (() -> Void)?) {
        self.updateTransactionHistory {
            self.updateBalance {
                self.delegate?.addressDidRequestExchangeRateHistoryUpdate(self)
                completion?()
            }
        }
    }
    
    /// fetches and saves balance if it has changed, notifies delegate
    final func updateBalance(completion: (() -> Void)?) {
        blockExplorer.fetchBalance(for: self) { balance, error in
            guard let balance = balance else {
                log.error("Failed to fetch balance for address '\(self.logDescription)': \(error!)")
                completion?()
                return
            }
            
            guard balance != self.balance else {
                log.verbose("Balance for address '\(self.logDescription)' is already-up-to-date.")
                completion?()
                return
            }
            
            do {
                self.balance = balance
                try self.context.save()
                log.debug("Updated balance (\(balance) \(self.blockchain.code)) for address '\(self.logDescription)'.")
                self.delegate?.addressDidUpdateBalance(self)
                completion?()
            } catch {
                log.error("Failed to save fetched balance for address '\(self.logDescription)': \(error).")
                completion?()
            }
        }
    }
    
    /// fetches and saves transaction history since last retrieved block, executes completion block if no error is thrown during retrieval and saving
    final func updateTransactionHistory(completion: (() -> Void)?) {
        let timeframe: Timeframe
        
        if lastBlock == 0 {
            timeframe = .allTime
        } else {
            timeframe = .sinceBlock(Int(lastBlock))
        }
        
        blockExplorer.fetchTransactionHistory(for: self, timeframe: timeframe) { transactions, error in
            guard let transactions = transactions else {
                log.error("Failed to fetch transaction history for address '\(self.logDescription)': \(error!)")
                completion?()
                return
            }
        
            var newTransactionsCount = 0
            
            for transactionPrototype in transactions {
                do {
                    let _ = try Transaction.createTransaction(from: transactionPrototype, owner: self, in: self.context)
                    newTransactionsCount = newTransactionsCount + 1
                    
                    if transactionPrototype.block > self.lastBlock {
                        self.lastBlock = Int64(transactionPrototype.block + 1)
                    }
                } catch {
                    log.error("Failed to create transaction '\(transactionPrototype.identifier)' for address '\(self.logDescription)': \(error)")
                }
            }
            
            self.lastUpdate = Date()
            
            do {
                guard newTransactionsCount > 0 else {
                    log.verbose("Transaction history for address '\(self.logDescription)' is already up-to-date.")
                    completion?()
                    return
                }
                
                try self.context.save()
                let multiple = (newTransactionsCount >= 2) || (newTransactionsCount == 0)
                log.debug("Updated transaction history for address '\(self.logDescription)' with \(newTransactionsCount) new transaction\(multiple ? "s" : "").")
                self.delegate?.addressDidUpdateTransactionHistory(self)
                completion?()
            } catch {
                log.error("Failed to save fetched transaction history for address '\(self.logDescription)': \(error)")
                completion?()
            }
        }
    }
    
    // MARK: Finance
    /// returns balance for specified transaction type on specified date
    final func getBalance(on date: Date, type: TransactionType) -> Double? {
        guard storedTransactions.count > 0 else {
            return 0.0
        }
    
        let transactions = getTransactions(type: type).filter { $0.date! <= date }
    
        var balance = 0.0
    
        for transaction in transactions {
            guard !transaction.isError else {
                // fee is paid nevertheless
                if transaction.isOutbound {
                    balance = balance - transaction.feeAmount
                }
                
                continue
            }
            
            if transaction.isOutbound {
                balance = balance - transaction.totalAmount
            } else {
                // fee is only paid by sender
                balance = balance + transaction.totalAmount - transaction.feeAmount
            }
        }
        
        return balance
    }
    
    // MARK: Cryptography
    func isValidAddress() -> Bool {
        preconditionFailure("This method must be overridden")
    }
    
    // MARK: - Transaction Delegate
    func transactionDidUpdateUserExchangeValue(_ transaction: Transaction) {
        delegate?.address(self, didNoticeUpdateForTransaction: transaction)
    }
    
    func transactionDidUpdateInvestmentStatus(_ transaction: Transaction) {
        delegate?.address(self, didNoticeUpdateForTransaction: transaction)
    }
    
}
