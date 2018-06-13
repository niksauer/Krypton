//
//  TokenCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class TokenCell: TappableCell {
    
    // MARK: - Private Properties
    private var token: Token!
    private var currencyFormatter: CurrencyFormatter!
    private var taxAdviser: TaxAdviser!
    
    // MARK: - Public Properties
    override var firstDetailValue: String? {
        get {
            return currencyFormatter.getCurrencyFormatting(for: token.balance, currency: token.storedToken)
        }
        set {
            self.firstDetailValue = newValue
        }
    }
    
    override var secondDetailValue: String? {
        get {
            if let exchangeValue = taxAdviser.getExchangeValue(for: token, on: Date()) {
                return currencyFormatter.getCurrencyFormatting(for: exchangeValue, currency: token.owner!.quoteCurrency)
            } else {
                return "???"
            }
        }
        set {
            self.firstDetailValue = newValue
        }
    }
    
    // MARK: - Initialization
    init(token: Token, currencyFormatter: CurrencyFormatter, taxAdviser: TaxAdviser, reuseIdentifier: String?) {
        self.token = token
        self.currencyFormatter = currencyFormatter
        self.taxAdviser = taxAdviser
        
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        textLabel?.text = token.storedToken.name
        showsFirstDetailValue = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
