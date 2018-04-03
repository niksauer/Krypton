//
//  DeleteCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.10.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DeleteCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var actionLabel: UILabel!
    
    // MARK: - Public Methods
    func configure(actionText: String) {
        actionLabel.text = actionText
    }

}
