//
//  TextFieldCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell, UITextFieldDelegate {
    
    // MARK: - Public Properties
    var completion: (() -> Void)?
    
    // MARK: - Outlets
    @IBOutlet weak var textField: UITextField!
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
    }
    
    // MARK: - Public Methods
    func configure(text: String?, placeholder: String?, completion: (() -> Void)?) {
        textField.text = text
        textField.placeholder = placeholder
        self.completion = completion
    }
    
    // MARK: - TextField Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        completion?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}
