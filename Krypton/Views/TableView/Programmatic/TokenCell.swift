//
//  TokenCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import ToolKit

class TokenCell: TappableDetailCell {
    
    // MARK: - Private Properties
    private var token: Token!
    private var currencyFormatter: CurrencyFormatter!
    private var taxAdviser: TaxAdviser!
    
    // MARK: - Public Properties
    override var firstDetailValue: String? {
        get {
            return currencyFormatter.getFormatting(for: token.balance, currency: token)
        }
        set {
            self.firstDetailValue = newValue
        }
    }
    
    override var secondDetailValue: String? {
        get {
            if let exchangeValue = taxAdviser.getExchangeValue(for: token, on: Date()) {
                return currencyFormatter.getFormatting(for: exchangeValue, currency: token.owner!.quoteCurrency)
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
        
        textLabel?.text = token.name
        showsFirstDetailValue = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
