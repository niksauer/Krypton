//
//  MessageCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var emptyMessageLabel: UILabel!
    
    // MARK: - Public Methods
    func configure(message: String) {
        emptyMessageLabel.text = message
    }

}
