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

protocol TokenFeatures: Currency {
    var name: String { get }
    var address: String { get }
}

class Token: NSManagedObject, Currency {
    
    // MARK: - Prototypes
    enum ERC20: String, TokenFeatures {
        case OMG
        case REP
        case STORJ
        
        // MARK: - Private Properties
        private static let nameForToken: [ERC20: String] = [
            .OMG: "OmiseGo",
            .REP: "Augur",
            .STORJ: "Storj"
        ]
        
        private static let addressForToken: [ERC20: String] = [
            .OMG: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07",
            .REP: "0xe94327d07fc17907b4db788e5adf2ed424addff6",
            .STORJ: "0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac"
        ]
        
        private static let decimalDigitsForToken: [ERC20: Int] = [
            .OMG: 18,
            .REP: 18,
            .STORJ: 8
        ]
        
        // MARK: - Public Properties
        static var allValues = [ OMG, REP, STORJ ]
        
        // MARK: - TokenFeatures Protocol
        var name: String {
            return ERC20.nameForToken[self]!
        }
        
        var address: String {
            return ERC20.addressForToken[self]!
        }
        
        // MARK: - Currency Protocol
        var code: String {
            return self.rawValue
        }
        
        var decimalDigits: Int {
            return ERC20.decimalDigitsForToken[self]!
        }
        
    }
    
    // MARK: - Public Class Methods
    class func createToken(from tokenInfo: TokenFeatures, owner: TokenAddress, in context: NSManagedObjectContext) throws -> Token {
        let request: NSFetchRequest<Token> = Token.fetchRequest()
        request.predicate = NSPredicate(format: "currencyCode = %@ AND owner = %@", tokenInfo.code, owner)
        
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
        token.address = tokenInfo.address
        token.name = tokenInfo.name
        token.currencyCode = tokenInfo.code
        token.currencyDecimalDigits = Int16(tokenInfo.decimalDigits)
        token.owner = owner
        
        return token
    }
    
    // MARK: - Currency Protocol
    var code: String {
        return currencyCode!
    }
    
    var decimalDigits: Int {
        return Int(currencyDecimalDigits)
    }

}
