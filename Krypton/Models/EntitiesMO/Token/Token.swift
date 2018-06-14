//
//  Token.swift
//  Krypton
//
//  Created by Niklas Sauer on 07.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import CoreData

enum TokenError: Error {
    case duplicate
    case invalidPrototype
}

class Token: NSManagedObject, Reportable, TokenFeatures {
    
    // MARK: - Public Class Methods
    class func createOrUpdate(from prototype: TokenProtoype, owner: TokenAddress, in context: NSManagedObjectContext) throws -> (token: Token, isNew: Bool) {
        let request: NSFetchRequest<Token> = Token.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@ AND owner = %@", prototype.address, owner)
        
        let matches = try context.fetch(request)
        
        if matches.count > 0 {
            assert(matches.count >= 1, "Token.createOrUpdate -- Database Inconsistency")
            
            // update existing token
            let token = matches.first!
            token.balance = prototype.balance
            token.identifier = prototype.address
            token.storedName = prototype.name
            token.storedSymbol = prototype.symbol
            token.storedDecimalDigits = Int16(prototype.decimalDigits)
            
            return (token, false)
        }
        
        let token = Token(context: context)
        
        token.balance = prototype.balance
        token.identifier = prototype.address
        token.storedName = prototype.name
        token.storedSymbol = prototype.symbol
        token.storedDecimalDigits = Int16(prototype.decimalDigits)
        
        return (token, true)
    }

    // MARK: - Public Properties
    var currencyPair: CurrencyPair {
        return CurrencyPair(base: self, quote: owner!.quoteCurrency)
    }
    
    // MARK: - Reportable
    var logDescription: String {
        return "\(self.identifier!), code: \(self.code), owner: \(self.owner!.logDescription)"
    }
    
    // MARK: - TokenFeatures
    var address: String {
        return identifier!
    }
    
    var blockchain: Blockchain {
        return owner!.blockchain
    }
    
    var code: String {
        return symbol
    }
    
    var name: String {
        return storedName!
    }
    
    var symbol: String {
        return storedSymbol!
    }
    
    var decimalDigits: Int {
        return Int(storedDecimalDigits)
    }
    
    var type: CurrencyType {
        return .Crypto
    }
    
}
