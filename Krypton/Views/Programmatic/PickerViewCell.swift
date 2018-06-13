//
//  PickerViewCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 06.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class PickerViewCell: UITableViewCell {

    // MARK: - Views
    let pickerView = UIPickerView()
    
    // MARK: - Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(pickerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func layoutSubviews() {
        super.layoutSubviews()
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.pin(to: contentView)
    }
    
}
