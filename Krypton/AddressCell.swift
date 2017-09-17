//
//  AddressCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AddressCell: UITableViewCell {

    @IBOutlet weak var addressField: UILabel!
    @IBOutlet weak var aliasField: UILabel!
    
    func configure(address: String, alias: String?) {
        addressField.text = address
        aliasField.text = alias
    }
    
}
