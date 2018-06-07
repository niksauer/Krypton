//
//  TransactionCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class TokenCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var tokenValueLabel: UILabel!
    
    // MARK: - Private Properties
    private var token: Token!
    private var currencyFormatter: CurrencyFormatter!
    private var taxAdviser: TaxAdviser!
    
    // MARK: - Public Properties
    var showsBalance = true {
        didSet {
            if showsBalance {
                tokenValueLabel.text = currencyFormatter.getCurrencyFormatting(for: token.balance, currency: token)
            } else {
                if let exchangeValue = taxAdviser.getExchangeValue(for: token, on: Date()) {
                    tokenValueLabel.text = currencyFormatter.getCurrencyFormatting(for: exchangeValue, currency: token.owner!.quoteCurrency)
                } else {
                    tokenValueLabel.text = "???"
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func configure(token: Token, currencyFormatter: CurrencyFormatter, taxAdviser: TaxAdviser, showsBalance: Bool) {
        self.token = token
        self.currencyFormatter = currencyFormatter
        self.taxAdviser = taxAdviser
        self.showsBalance = showsBalance
        
        tokenNameLabel.text = token.name
    }

}
