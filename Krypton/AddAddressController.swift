//
//  AddAddressController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AddAddressController: UITableViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, PortfolioSelectorDelegate {
    
    // MARK: - Public Properties
    var selectedPortfolio: Portfolio? {
        didSet {
            selectedPortfolioLabel.text = selectedPortfolio != nil ? selectedPortfolio?.alias : "None"
        }
    }
    
    var selectedBlockchain: Blockchain? {
        didSet {
            selectedBlockchainLabel.text = selectedBlockchain?.name
        }
    }
    
    // MARK: - Private Properties
    private let blockchains = Blockchain.allValues
    private let blockchainFieldIndexPath = IndexPath(row: 0, section: 1)
    private let blockchainPickerIndexPath = IndexPath(row: 1, section: 1)
    private let portfolioIndexPath = IndexPath(row: 0, section: 2)
    
    // MARK: - Outlets
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var aliasField: UITextField!
    @IBOutlet weak var selectedBlockchainLabel: UILabel!
    @IBOutlet weak var blockchainPicker: UIPickerView!
    @IBOutlet weak var selectedPortfolioLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedPortfolio = PortfolioManager.shared.defaultPortfolio
        selectedBlockchain = blockchains.first
        
        blockchainPicker.delegate = self
        blockchainPicker.dataSource = self
        blockchainPicker.selectRow(0, inComponent: 0, animated: true)
        blockchainPicker.isHidden = true
        
        addressField.delegate = self
        aliasField.delegate = self
        
        checkSaveButton()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? PortfolioTableController {
            destVC.delegate = self
            destVC.isSelector = true
            destVC.selectedPortfolio = selectedPortfolio
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard let addressString = addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !addressString.isEmpty, selectedPortfolio != nil, selectedBlockchain != nil else {
            return
        }
        
        let alias = aliasField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try selectedPortfolio!.addAddress(addressString, alias: alias, blockchain: selectedBlockchain!)
            dismiss(animated: true, completion: nil)
        } catch {
            // present error
            print("Failed to add address due to error: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func checkSaveButton() {
        guard let addressString = addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !addressString.isEmpty, selectedPortfolio != nil, selectedBlockchain != nil else {
            saveButton.isEnabled = false
            return
        }
        
        saveButton.isEnabled = true
    }
    
    // MARK: - PortfolioSelector Delegate
    func didChangeSelection(selection: Portfolio?) {
        selectedPortfolio = selection
        checkSaveButton()
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case _ where indexPath == blockchainPickerIndexPath:
            if blockchainPicker.isHidden {
                return 0
            } else {
                return 220
            }
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case _ where indexPath == blockchainFieldIndexPath:
            blockchainPicker.isHidden = !blockchainPicker.isHidden
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.tableView.beginUpdates()
                // apple bug fix - some TV lines hide after animation
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.tableView.endUpdates()
            })
        default:
            return
        }
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextField = tableView.viewWithTag(textField.tag + 1) as? UITextField {
            nextTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        checkSaveButton()
        return false
    }
    
    // MARK: - PickerView Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return blockchains.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return blockchains[row].name
    }
    
    // MARK: - PickerView Delegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedBlockchain = blockchains[row]
        checkSaveButton()
    }
    
}
