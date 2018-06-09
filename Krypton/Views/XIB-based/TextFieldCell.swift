//
//  TextFieldCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet private weak var textField: UITextField!
    
    // MARK: - Private Properties
    private var onChange: ((String?) -> Void)?
    
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
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.addTarget(self, action: #selector(textFieldValueChanged(_:)), for: .editingChanged)
    }
    
    // MARK: - Public Methods
    func configure(text: String?, placeholder: String?, isEnabled: Bool, onChange: ((String?) -> Void)?) {
        textField.text = text
        textField.placeholder = placeholder
        self.isEnabled = isEnabled
        self.onChange = onChange
    }
    
    // MARK: - TextField Delegate
    @objc private func textFieldValueChanged(_ sender: UITextField) {
        onChange?(sender.text)
    }
    
}
