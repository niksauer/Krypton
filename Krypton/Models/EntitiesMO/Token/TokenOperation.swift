//
//  TokenOperation.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

enum TokenOperationError: Error {
    case invalidOperation
    case duplicate
}

class TokenOperation: NSManagedObject {
    
    // MARK: - Public Class Methods
    class func create(from prototype: TokenOperationPrototype, token: Token, in context: NSManagedObjectContext) throws -> TokenOperation {
        let request: NSFetchRequest<TokenOperation> = TokenOperation.fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@ AND token = %@", prototype.identifier, token)
        
        let matches = try context.fetch(request)
        
        if matches.count > 0 {
            assert(matches.count >= 1, "TokenOperation.createOrUpdate -- Database Inconsistency")
            throw TokenOperationError.duplicate
        }

        let operation = TokenOperation(context: context)
        
        operation.amount = prototype.amount
        operation.block = Int64(prototype.block)
        operation.date = prototype.date
        operation.from = prototype.from
        operation.identifier = prototype.identifier
        operation.to = prototype.to
        operation.typeRaw = prototype.type.rawValue
        operation.isOutbound = (token.owner!.identifier == prototype.from)
        
        operation.token = token
        
        return operation
    }
    
}
