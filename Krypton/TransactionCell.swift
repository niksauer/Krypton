//
//  TransactionCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 28.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class TransactionCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    // MARK: - Public Methods
    func configure(transaction: Transaction) {
        dateLabel.text = Format.getDateFormatting(for: transaction.date!)
        
        if transaction.isOutbound {
//            addressLabel.text = transaction.to as? String
        } else {
//            addressLabel.text = transaction.from
        }
        
        amountLabel.text = Format.getCurrencyFormatting(for: transaction.amount, currency: transaction.owner!.blockchain)
    }

}
