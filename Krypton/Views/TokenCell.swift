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
    
    // MARK: - Public Properties
    var showsBalance = true {
        didSet {
            if showsBalance {
                tokenValueLabel.text = Format.getCurrencyFormatting(for: token.balance, currency: token)
            } else {
                if let exchangeValue = token.getExchangeValue(on: Date()) {
                    tokenValueLabel.text = Format.getCurrencyFormatting(for: exchangeValue, currency: token.owner!.quoteCurrency)
                } else {
                    tokenValueLabel.text = "???"
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func configure(token: Token, showsBalance: Bool) {
        self.token = token
        self.showsBalance = showsBalance
        
        tokenNameLabel.text = token.name
    }

}
