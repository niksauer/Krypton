//
//  PortfolioDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class PortfolioDetailController: UITableViewController {
    
    // MARK: - Public Properties
    var portfolio: Portfolio!
    var allowsAddressSelection = false
    
    let aliasIndexPath = IndexPath(row: 0, section: 0)
    let isDefaultIndexPath = IndexPath(row: 1, section: 0)
    
    // MARK: - Initilization
    override func viewDidLoad() {
        super.viewDidLoad()
        checkEditButton()
    }

    // MARK: - Public Methods
    /// enables edit button if portfolio has at least one associated address
    func checkEditButton() {
        if portfolio.storedAddresses.count > 0 {
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    func removeAddress(_ address: Address) {
        do {
            try portfolio.removeAddress(address: address)
            tableView.reloadData()
            checkEditButton()
        } catch {
            // present error
            print(error)
        }
    }
    
    func deletePortfolio() {
        do {
            try PortfolioManager.shared.removePortfolio(portfolio)
            self.navigationController?.popViewController(animated: true)
        } catch {
            // present error
            print(error)
        }
    }
    
    func setAlias() {
        if let newAlias = (tableView.cellForRow(at: aliasIndexPath) as! TextFieldCell).textField.text, !newAlias.isEmpty {
            do {
                try portfolio.setAlias(newAlias)
            } catch {
                // present error
                print(error)
            }
        }
    }
    
    func setIsDefault() {
        let state = (tableView.cellForRow(at: isDefaultIndexPath) as! SwitchCell).toggleSwitch.isOn
        
        do {
            try portfolio.setIsDefault(state)
        } catch {
            // present error
            print(error)
        }
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if portfolio.storedAddresses.count > 0 {
            return 3
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if portfolio.storedAddresses.count > 0, section == 1 {
            return portfolio.storedAddresses.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath == aliasIndexPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! TextFieldCell
            cell.configure(text: portfolio?.alias, placeholder: "Alias", completion: setAlias)
            cell.textField.clearButtonMode = .always
            return cell
        }
        
        if indexPath == isDefaultIndexPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
            cell.configure(name: "Default", state: portfolio.isDefault, completion: setIsDefault)
            return cell
        }
        
        if portfolio.storedAddresses.count > 0, indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath) as! AddressCell
            let address = portfolio.storedAddresses[indexPath.row]
            cell.configure(address: address.address!, alias: address.alias)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "deleteCell", for: indexPath)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "General"
        } else if portfolio.storedAddresses.count > 0, section == 1 {
            return "Addresses"
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if portfolio.storedAddresses.count > 0, indexPath.section == 1 {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let address = portfolio.storedAddresses[indexPath.row]
            removeAddress(address)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if portfolio.storedAddresses.count > 0 && indexPath.section == 2 || portfolio.storedAddresses.count == 0 && indexPath.section == 1 {
            deletePortfolio()
        } else if allowsAddressSelection {
            performSegue(withIdentifier: "showAddress", sender: self)
        }
    }

}