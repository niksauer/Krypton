//
//  Token.swift
//  Krypton
//
//  Created by Niklas Sauer on 07.10.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum TokenError: Error {
    case duplicate
    case invalidBlockchain
}

class Token: NSManagedObject, TokenFeatures {
    
    // MARK: - Private Properties
    private var token: TokenFeatures {
        return owner!.blockchain.getToken(address: identifier!)!
    }
    
    // MARK: - Public Properties
    var currencyPair: CurrencyPair {
        return CurrencyPair(base: self, quote: owner!.quoteCurrency)
    }
    
    // MARK: - Currency Protocol
    var code: String {
        return token.code
    }
    
    var name: String {
        return token.name
    }
    
    var symbol: String {
        return token.symbol
    }
    
    var decimalDigits: Int {
        return token.decimalDigits
    }
    
    var type: CurrencyType {
        return token.type
    }
    
    // MARK: - TokenFeatures Protocol
    var address: String {
        get {
            return identifier!
        }
        set {
            self.identifier = newValue
        }
    }
    
    var blockchain: Blockchain {
        return token.blockchain
    }

    // MARK: - Public Class Methods
    class func createToken(from tokenInfo: TokenFeatures, owner: TokenAddress, in context: NSManagedObjectContext) throws -> Token {
        guard owner.blockchain == tokenInfo.blockchain else {
            throw TokenError.invalidBlockchain
        }
        
        let request: NSFetchRequest<Token> = Token.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@ AND owner = %@", tokenInfo.address, owner)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Token.createToken -- Database Inconsistency")
                throw TokenError.duplicate
            }
        } catch {
            throw error
        }
        
        let token = Token(context: context)
        
        token.identifier = tokenInfo.address
        token.owner = owner
        
        return token
    }

}
