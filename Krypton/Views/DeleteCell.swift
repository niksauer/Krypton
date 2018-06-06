//
//  DeleteCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class DeleteCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet private weak var actionLabel: UILabel!
    
    // MARK: - Public Methods
    func configure(actionText: String) {
        actionLabel.text = actionText
    }

}
