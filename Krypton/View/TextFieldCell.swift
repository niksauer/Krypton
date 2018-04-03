//
//  TextFieldCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell, UITextFieldDelegate {
    
    // MARK: - Private Properties
    private var completion: ((String?) -> Void)?
    
    // MARK: - Public Properties
    var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                textField.isUserInteractionEnabled = true
                textField.clearButtonMode = .always
            } else {
                textField.isUserInteractionEnabled = false
                textField.clearButtonMode = .never
            }
        }
    }
    
    // MARK: - Outlets
    @IBOutlet private weak var textField: UITextField!
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
    }
    
    // MARK: - Public Methods
    func configure(text: String?, placeholder: String?, isEnabled: Bool, completion: ((String?) -> Void)?) {
        textField.text = text
        textField.placeholder = placeholder
        self.isEnabled = isEnabled
        self.completion = completion
    }
    
    // MARK: - TextField Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        completion?(textField.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}
