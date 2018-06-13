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
    case invalidOwner
}

class Token: NSManagedObject, Reportable {
        
    // MARK: - Public Class Methods
    class func createToken(from prototype: TokenFeatures, owner: TokenAddress, in context: NSManagedObjectContext) throws -> Token {
        guard owner.blockchain == prototype.blockchain else {
            throw TokenError.invalidOwner
        }
        
        let request: NSFetchRequest<Token> = Token.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@ AND owner = %@", prototype.address, owner)
        
        let matches = try context.fetch(request)
        
        if matches.count > 0 {
            assert(matches.count >= 1, "Token.createToken -- Database Inconsistency")
            throw TokenError.duplicate
        }
        
        let token = Token(context: context)
        
        token.identifier = prototype.address
        token.owner = owner
        
        return token
    }

    // MARK: - Public Properties
    var storedToken: TokenFeatures {
        return owner!.blockchain.getToken(address: identifier!)!
    }
    
    var currencyPair: CurrencyPair {
        return CurrencyPair(base: storedToken, quote: owner!.quoteCurrency)
    }
    
    // MARK: - Reportable
    var logDescription: String {
        return "\(self.identifier!), code: \(storedToken.code), owner: \(self.owner!.logDescription)"
    }
    
}
