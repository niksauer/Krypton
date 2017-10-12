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
            if selectedPortfolio == nil {
                selectedPortfolioLabel.text = "None"
            } else {
                selectedPortfolioLabel.text = selectedPortfolio?.alias ?? "???"
            }
        }
    }
    
    var selectedBlockchain: Blockchain = .XBT {
        didSet {
            blockchainLabel.text = selectedBlockchain.name
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
    
    @IBOutlet weak var blockchainLabel: UILabel!
    @IBOutlet weak var blockchainPicker: UIPickerView!
    
    @IBOutlet weak var selectedPortfolioLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blockchainPicker.delegate = self
        blockchainPicker.dataSource = self
        blockchainPicker.selectRow(0, inComponent: 0, animated: true)
        blockchainPicker.isHidden = true
        
        addressField.delegate = self
        aliasField.delegate = self
        
        selectedPortfolio = PortfolioManager.shared.defaultPortfolio
        
        checkSaveButton()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? PortfolioTableController {
            destVC.isSelector = true
            destVC.delegate = self
            destVC.selectedPortfolio = selectedPortfolio
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard let addressString = addressField.text, !addressString.isEmpty, selectedPortfolio != nil else {
            return
        }
        
        do {
            try selectedPortfolio?.addAddress(addressString, alias: aliasField.text, blockchain: selectedBlockchain)
            dismiss(animated: true, completion: nil)
        } catch {
            print("Failed to add address due to error: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func checkSaveButton() {
        guard let addressString = addressField.text, !addressString.isEmpty, selectedPortfolio != nil else {
            saveButton.isEnabled = false
            return
        }
        
        saveButton.isEnabled = true
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == blockchainPickerIndexPath {
            if blockchainPicker.isHidden {
                return 0
            } else {
                return 220
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       if indexPath == blockchainFieldIndexPath {
            blockchainPicker.isHidden = !blockchainPicker.isHidden
        
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.tableView.beginUpdates()
                // apple bug fix - some TV lines hide after animation
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.tableView.endUpdates()
            })
        }
    }
    
    // MARK: - PortfolioSelector Delegate
    func didChangeSelection(selection: Portfolio?) {
        selectedPortfolio = selection
        checkSaveButton()
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
    
    // MARK: - PickerView Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return blockchains.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return blockchains[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedBlockchain = blockchains[row]
    }
    
}
