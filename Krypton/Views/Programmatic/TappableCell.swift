//
//  TappableCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 08.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class TappableCell: UITableViewCell {
    
    // Mark: - Public Properties
    var firstDetailValue: String?
    var secondDetailValue: String?
    
    var showsFirstDetailValue = true {
        didSet {
            if showsFirstDetailValue {
                detailTextLabel?.text = firstDetailValue
            } else {
                detailTextLabel?.text = secondDetailValue
            }
        }
    }
    
    // Mark: - Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
