//
//  TextFieldCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell {
    
    // MARK: - Views
    let textField = UITextField()
    
    // MARK: - Public Properties
    var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                textField.isUserInteractionEnabled = true
                textField.clearButtonMode = isEnabledClearButtonMode
            } else {
                textField.isUserInteractionEnabled = false
                textField.clearButtonMode = .never
            }
        }
    }
    
    var isEnabledClearButtonMode: UITextFieldViewMode = .whileEditing {
        didSet {
            isEnabled = { isEnabled }()
        }
    }
    
    // MARK: - Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        contentView.addSubview(textField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

}
