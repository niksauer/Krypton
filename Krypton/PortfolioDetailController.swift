//
//  PortfolioDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class PortfolioDetailController: UITableViewController {
    
    // MARK: - Private Properties
    private let aliasIndexPath = IndexPath(row: 0, section: 0)
    private let isDefaultIndexPath = IndexPath(row: 1, section: 0)
    private var deleteIndexPath: IndexPath!
    private var selectedAddress: Address?
    
    // MARK: - Public Properties
    var portfolio: Portfolio!
    
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? AddresDetailController {
            destVC.address = selectedAddress
        }
    }

    // MARK: - Public Methods
    func removeAddress(_ address: Address) {
        do {
            try portfolio.removeAddress(address: address)
            tableView.reloadData()
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
    
    func setAlias(_ alias: String?) {
        guard let alias = alias?.trimmingCharacters(in: .whitespacesAndNewlines), !alias.isEmpty else {
            return
        }
        
        do {
            try portfolio.setAlias(alias)
        } catch {
            // present error
            print(error)
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
        switch section {
        case _ where section == 0:
            return 2
        case _ where section == 1 && portfolio.storedAddresses.count > 0:
            return portfolio.storedAddresses.count
        default:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case _ where indexPath == aliasIndexPath:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! TextFieldCell
            cell.configure(text: portfolio?.alias, placeholder: "Alias", completion: setAlias)
            cell.textField.clearButtonMode = .always
            return cell
        case _ where indexPath == isDefaultIndexPath:
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
            cell.configure(name: "Default", state: portfolio.isDefault, completion: setIsDefault)
            return cell
        case _ where indexPath.section == 1 && portfolio.storedAddresses.count > 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath) as! AddressCell
            let address = portfolio.storedAddresses[indexPath.row]
            cell.configure(address: address.identifier!, alias: address.alias)
            return cell
        default:
            deleteIndexPath = indexPath
            let cell = tableView.dequeueReusableCell(withIdentifier: "deleteCell", for: indexPath)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case _ where section == 0:
            return "Portfolio"
        case _ where section == 1 && portfolio.storedAddresses.count > 0:
            return "Addresses"
        default:
            return nil
        }
    }
    
    // MARK: - TableView Delegate
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
        guard indexPath != aliasIndexPath, indexPath != isDefaultIndexPath else {
            return
        }
        
        if indexPath == deleteIndexPath {
            deletePortfolio()
        } else {
            selectedAddress = portfolio.storedAddresses[indexPath.row]
            performSegue(withIdentifier: "showAddress", sender: self)
        }
    }

}
