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

class Address: NSManagedObject, TransactionDelegate {
    
    // MARK: - Public Class Methods
    /// creates and returns address if non-existent in database, throws otherwise
    class func createAddress(_ addressString: String, alias: String?, blockchain: Blockchain, quoteCurrency: Currency, in context: NSManagedObjectContext) throws -> Address {
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@", addressString)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Address.createAddress -- Database Inconsistency")
                throw AddressError.duplicate
            }
        } catch {
            throw error
        }
        
        let address: Address
        
        switch blockchain {
        case .ETH:
            address = Ethereum(context: context)
        case .BTC:
            address = Bitcoin(context: context)
        }
    
        address.identifier = addressString
        
        guard address.isValidAddress() else {
            context.delete(address)
            throw AddressError.invalidFormat
        }
        
        address.alias = alias
        address.quoteCurrencyCode = quoteCurrency.code
        
        return address
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext = CoreDataStack.shared.viewContext
    private let currencyManager: CurrencyManager = CurrencyManager()
    
    // MARK: - Public Properties
    /// delegate who gets notified of changes in balance, transaction history and all associated transactions' userExchangeValue, isInvestment properties
    var delegate: AddressDelegate?
    
    var blockchain: Blockchain {
        get {
            return Blockchain(rawValue: blockchainRaw!)!
        }
    }
    
    private(set) public var quoteCurrency: Currency {
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
    func getOldestTransaction() -> Transaction? {
        return storedTransactions.max(by: { $0.date! < $1.date! })
    }
    
    func getTransactions(of type: TransactionType) -> [Transaction] {
        switch type {
        case .investment:
            return storedTransactions.filter { $0.isInvestment }
        case .other:
            return storedTransactions.filter { !$0.isInvestment }
        case .all:
            return storedTransactions
        }
    }
    
    func setAlias(_ alias: String) throws {
        guard self.alias != alias else {
            return
        }
        
        do {
            self.alias = alias
            try context.save()
            log.debug("Updated alias for address '\(logDescription)'.")
            delegate?.addressDidUpdateAlias(self)
        } catch {
            log.error("Failed to update alias for address '\(logDescription)': \(error)")
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
            log.debug("Updated quote currency (\(currency.code)) for address '\(logDescription)'.")
            delegate?.addressDidUpdateQuoteCurrency(self)
        } catch {
            log.error("Failed to update quote currency for address '\(logDescription)': \(error)")
            throw error
        }
    }
    
    func setPortfolio(_ portfolio: Portfolio) throws {
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
    func updateBalance(completion: (() -> Void)?) {
        BlockchainConnector.fetchBalance(for: self) { result in
            switch result {
            case .success(let balance):
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
                }
            case .failure(let error):
                log.error("Failed to fetch balance for address '\(self.logDescription)': \(error)")
            }
        }
    }
    
    /// fetches and saves transaction history since last retrieved block, executes completion block if no error is thrown during retrieval and saving
    func updateTransactionHistory(completion: (() -> Void)?) {
        let timeframe: TransactionHistoryTimeframe
        
        if lastBlock == 0 {
            timeframe = .allTime
        } else {
            timeframe = .sinceBlock(Int(lastBlock))
        }
        
        BlockchainConnector.fetchTransactionHistory(for: self, timeframe: timeframe) { result in
            switch result {
            case .success(let txs):
                var newTxCount = 0
                
                for txInfo in txs {
                    do {
                        let transaction = try Transaction.createTransaction(from: txInfo, owner: self, in: self.context)
                        newTxCount = newTxCount + 1
                        
                        if transaction.block > self.lastBlock {
                            self.lastBlock = transaction.block + 1
                        }
                    } catch {
                        log.error("Failed to create transaction '\(txInfo.identifier)' for address '\(self.logDescription)': \(error)")
                    }
                }
                
                self.lastUpdate = Date()
                
                do {
                    if self.context.hasChanges, newTxCount > 0 {
                        try self.context.save()
                        let multiple = (newTxCount >= 2) || (newTxCount == 0)
                        log.debug("Updated transaction history for address '\(self.logDescription)' with \(newTxCount) new transaction\(multiple ? "s" : "").")
                    } else {
                        log.verbose("Transaction history for address '\(self.logDescription)' is already up-to-date.")
                    }
                    
                    self.delegate?.addressDidUpdateTransactionHistory(self)
                    completion?()
                } catch {
                    log.error("Failed to save fetched transaction history for address '\(self.logDescription)': \(error)")
                }
            case .failure(let error):
                log.error("Failed to fetch transaction history for address '\(self.logDescription)': \(error)")
            }
        }
    }
    
    // MARK: Finance
    /// returns balance for specified transaction type on specified date
    func getBalance(for type: TransactionType, on date: Date) -> Double? {
        guard storedTransactions.count > 0 else {
            return 0.0
        }
        
        let transactions = getTransactions(of: type).filter { $0.date! <= date }
        var balance = 0.0
    
        for transaction in transactions {
            if transaction.isOutbound {
                balance = balance - transaction.totalAmount
            } else {
                balance = balance + transaction.totalAmount
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

class Bitcoin: Address {

    // MARK: - Initializers
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Blockchain.BTC.rawValue, forKey: "blockchainRaw")
    }
    
    // MARK: - Public Methods    
    // MARK: Cryptography
    override func isValidAddress() -> Bool {
        let regex = NSPredicate(format: "SELF MATCHES %@", "^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$")
        return regex.evaluate(with: identifier!)
    }

}
