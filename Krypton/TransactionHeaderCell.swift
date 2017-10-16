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
    
    // MARK: - Public Methods
    func configure(amount: Double, currency: Currency, date: Date) {
        amountLabel.text = Format.getCurrencyFormatting(for: amount, currency: currency)
        dateLabel.text = Format.getDateFormatting(for: date)
    }

}
