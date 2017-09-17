//
//  AddAddressController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AddAddressController: UITableViewController, PortfolioSelectorDelegate, UITextFieldDelegate {
    
    // MARK: - Public Properties
    var portfolio: Portfolio? = PortfolioManager.shared.defaultPortfolio
    
    let cryptoData = Currency.Crypto.allValues
    let cryptoFieldIndexPath = IndexPath(row: 0, section: 1)
    let cryptoPickerIndexPath = IndexPath(row: 1, section: 1)
    let portfolioIndexPath = IndexPath(row: 0, section: 2)
    
    // MARK: - Outlets
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var aliasField: UITextField!
    
    @IBOutlet weak var cryptoField: UITableViewCell!
    @IBOutlet weak var cryptoPicker: UIPickerView!
    
    @IBOutlet weak var selectedPortfolioLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cryptoPicker.delegate = self
        cryptoPicker.dataSource = self
        cryptoPicker.selectRow(0, inComponent: 0, animated: true)
        cryptoPicker.isHidden = true
        
        selectedPortfolioLabel.text = portfolio?.alias ?? "None"
        
        addressField.delegate = self
        aliasField.delegate = self
        
        checkSaveButton()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? PortfolioTableController {
            destVC.isSelector = true
            destVC.delegate = self
            destVC.selectedPortfolio = portfolio
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard let addressString = addressField.text, !addressString.isEmpty, let selectedUnit = cryptoField.detailTextLabel?.text, let cryptoUnit = Currency.Crypto(rawValue: selectedUnit), portfolio != nil else {
            return
        }
        
        do {
            try portfolio?.addAddress(addressString, unit: cryptoUnit, alias: aliasField.text)
            performSegue(withIdentifier: "unwindToDashboard", sender: self)
        } catch {
            print("Failed to add address due to error: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func checkSaveButton() {
        guard let addressString = addressField.text, !addressString.isEmpty, let selectedUnit = cryptoField.detailTextLabel?.text, let _ = Currency.Crypto(rawValue: selectedUnit), portfolio != nil else {
            saveButton.isEnabled = false
            return
        }
        
        saveButton.isEnabled = true
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == cryptoPickerIndexPath {
            if cryptoPicker.isHidden {
                return 0
            } else {
                return 220
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       if indexPath == cryptoFieldIndexPath {
            cryptoPicker.isHidden = !cryptoPicker.isHidden
        
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
        if let selectedPortfolio = selection {
            portfolio = selectedPortfolio
            selectedPortfolioLabel.text = selectedPortfolio.alias
        } else {
            selectedPortfolioLabel.text = "None"
        }
        
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
    
}

// MARK: - PickerView Delegate
extension AddAddressController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cryptoData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return cryptoData[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        cryptoField.detailTextLabel?.text = cryptoData[row].rawValue
    }
    
}
