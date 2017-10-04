//
//  AddPortfolioController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AddPortfolioController: UITableViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var aliasField: UITextField!
    @IBOutlet weak var isDefaultSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // MARK: - Properties
    var delegate: PortfolioCreatorDelegate?
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        aliasField.delegate = self
        
        if PortfolioManager.shared.defaultPortfolio == nil {
            isDefaultSwitch.isOn = true
        }
    }
    
    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard let aliasString = aliasField.text, !aliasString.isEmpty else {
            return
        }
        
        delegate?.shouldCreatePortfolio(alias: aliasString, isDefault: isDefaultSwitch.isOn)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Methods
    func checkSaveButton() {
        guard let aliasString = aliasField.text, !aliasString.isEmpty else {
            saveButton.isEnabled = false
            return
        }
        
        saveButton.isEnabled = true
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        checkSaveButton()
        return false
    }

}

protocol PortfolioCreatorDelegate {
    func shouldCreatePortfolio(alias: String, isDefault: Bool)
}
