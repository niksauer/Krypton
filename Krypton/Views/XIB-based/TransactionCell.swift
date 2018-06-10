//
//  TransactionCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class TransactionCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    // MARK: - Public Methods
    func configure(transaction: Transaction, dateFormatter: DateFormatter, currencyFormatter: CurrencyFormatter) {
        dateLabel.text = dateFormatter.string(from: transaction.date!)
        amountLabel.text = currencyFormatter.getCurrencyFormatting(for: transaction.totalAmount, currency: transaction.owner!.blockchain)
        
        if transaction.isOutbound {
            addressLabel.text = transaction.primaryReceiver
            amountLabel.textColor = UIColor.red
        } else {
            addressLabel.text = transaction.primarySender
            amountLabel.textColor = UIColor.green
        }
    }

}
