//
//  TransactionHeaderCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.10.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class TransactionHeaderCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var isErrorImage: UIImageView!
    @IBOutlet weak var isInvestmentImage: UIImageView!
    
    // MARK: - Public Methods
    func configure(transaction: Transaction) {
        amountLabel.text = Format.getCurrencyFormatting(for: transaction.totalAmount, currency: transaction.owner!.blockchain)
        
        if transaction.isOutbound {
            amountLabel.textColor = UIColor.red
        } else {
            amountLabel.textColor = UIColor.green
        }
        
        dateLabel.text = Format.getDateFormatting(for: transaction.date!)
    
        isInvestmentImage.isHidden = !transaction.isInvestment
        isErrorImage.isHidden = !transaction.isError
    }

}
