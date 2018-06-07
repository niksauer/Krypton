//
//  Transaction.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

enum TransactionError: Error {
    case duplicate
    case invalidPrototype
}

protocol TransactionDelegate {
    func transactionDidUpdateUserExchangeValue(_ transaction: Transaction)
    func transactionDidUpdateInvestmentStatus(_ transaction: Transaction)
}

class Transaction: NSManagedObject {
    
    // MARK: - Public Class Methods
    /// creates and returns transaction if non-existent in database, throws otherwise
    class func createTransaction(from prototype: TransactionPrototype, owner: Address, in context: NSManagedObjectContext) throws -> Transaction {
        guard prototype.from.count >= 1, prototype.to.count >= 1 else {
            throw TransactionError.invalidPrototype
        }
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        switch owner {
        case is Ethereum:
            guard let prototype = prototype as? EthereumTransactionPrototype else {
                throw TransactionError.invalidPrototype
            }
            
            request.predicate = NSPredicate(format: "identifier = %@ AND owner = %@ AND type = %@ ", prototype.identifier, owner, prototype.type.rawValue)
        default:
            request.predicate = NSPredicate(format: "identifier = %@ AND owner = %@", prototype.identifier, owner)
        }
    
        let transaction: Transaction
        
        switch owner {
        case is Ethereum:
            guard let prototype = prototype as? EthereumTransactionPrototype, prototype.from.count == 1, prototype.to.count == 1 else {
                throw TransactionError.invalidPrototype
            }
            
            let ethereumTransaction = EthereumTransaction(context: context)
            ethereumTransaction.type = prototype.type.rawValue
            ethereumTransaction.isError = prototype.isError
            
            transaction = ethereumTransaction
        case is Bitcoin:
            guard let prototype = prototype as? BitcoinTransactionPrototype else {
                throw TransactionError.invalidPrototype
            }
            
            let bitcoinTransaction = BitcoinTransaction(context: context)
            bitcoinTransaction.amountFromSender = NSDictionary(dictionary: prototype.amountFromSender)
            bitcoinTransaction.amountForReceiver = NSDictionary(dictionary: prototype.amountForReceiver)
            
            transaction = bitcoinTransaction
        default:
            transaction = Transaction(context: context)
        }
        
        transaction.identifier = prototype.identifier
        transaction.date = prototype.date
        transaction.totalAmount = prototype.totalAmount
        transaction.feeAmount = prototype.feeAmount
        transaction.block = Int32(prototype.block)
        transaction.to = prototype.to as NSObject
        transaction.from = prototype.from as NSObject
        transaction.isOutbound = prototype.isOutbound
        transaction.owner = owner
        
        return transaction
    }
    
    // MARK: - Initialization
    override func awakeFromFetch() {
        super.awakeFromFetch()
        delegate = owner
    }
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext = CoreDataStack.shared.viewContext
    
    // MARK: - Public Properties
    var delegate: TransactionDelegate?
    
    var senders: [String] {
        return from as! [String]
    }
    
    var primarySender: String {
        return senders.contains(self.owner!.identifier!) ? self.owner!.identifier! : senders.first!
    }
    
    var receivers: [String] {
        return to as! [String]
    }
    
    var primaryReceiver: String {
        return receivers.contains(self.owner!.identifier!) ? self.owner!.identifier! : receivers.first!
    }
    
    var logDescription: String {
        return "\(self.identifier!), owner: \(self.owner!.logDescription)"
    }
    
    var hasUserExchangeValue: Bool {
        return userExchangeValue != -1
    }
    
    // MARK: - Public Methods
    /// replaces exchange value as encountered on execution date by user specified value, notifies owner's delegate if change occurred
    func setUserExchangeValue(value newValue: Double) throws {
        guard newValue != userExchangeValue else {
            return
        }
        
        do {
            userExchangeValue = newValue
            try context.save()
            log.debug("Updated user exchange value (\(newValue)) for transaction '\(self.logDescription)'.")
            self.delegate?.transactionDidUpdateUserExchangeValue(self)
        } catch {
            log.error("Failed to update user exchange value for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    /// updates isInvestment status as specified by user, notifies owner's delegate if change occurred
    func setIsInvestment(state newValue: Bool) throws {
        guard newValue != isInvestment else {
            return
        }
        
        do {
            isInvestment = newValue
            try context.save()
            log.debug("Updated isInvestment status (\(newValue)) for transaction '\(self.logDescription)'.")
            self.delegate?.transactionDidUpdateInvestmentStatus(self)
        } catch {
            log.error("Failed to update isInvestment status for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    func setIsUnread(state newValue: Bool) throws {
        guard newValue != isUnread else {
            return
        }
        
        do {
            isUnread = newValue
            try context.save()
            log.debug("Updated isUnread status (\(newValue)) for transaction '\(self.logDescription)'.")
        } catch {
            log.error("Failed to update isUnread status for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
    func resetUserExchangeValue() throws {
        do {
            userExchangeValue = -1
            try context.save()
            log.debug("Reset user exchange value for transaction '\(self.logDescription)'.")
            self.delegate?.transactionDidUpdateUserExchangeValue(self)
        } catch {
            log.error("Failed to reset user exchange value for transaction '\(self.logDescription)': \(error)")
            throw error
        }
    }
    
}

class EthereumTransaction: Transaction {
    
}

class BitcoinTransaction: Transaction {
    
}
