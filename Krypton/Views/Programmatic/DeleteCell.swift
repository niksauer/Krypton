//
//  DeleteCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class DeleteCell: CenterLabelCell {
    
    // MARK: - Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        label.textColor = UIColor.red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}



