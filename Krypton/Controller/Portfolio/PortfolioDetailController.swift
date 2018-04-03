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
    private var selectedAddress: Address?
    private var aliasCell: TextFieldCell!
    
    // MARK: - Public Properties
    var portfolio: Portfolio!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        let deleteSection = IndexSet(integer: (portfolio.storedAddresses.count > 0) ? 2 : 1)
        
        if isEditing {
            aliasCell.isEnabled = true
            tableView.insertSections(deleteSection, with: .top)
        } else {
            aliasCell.isEnabled = false
            tableView.deleteSections(deleteSection, with: .top)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? AddressDetailController, let selection = tableView.indexPathForSelectedRow?.row {
            destVC.address = portfolio.storedAddresses[selection]
        }
    }

    // MARK: - Public Methods
    func deletePortfolio() {
        do {
            try PortfolioManager.shared.removePortfolio(portfolio)
            self.navigationController?.popViewController(animated: true)
        } catch {
            // present error
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
        }
    }
    
    func setIsDefault(_ state: Bool) {
        do {
            try portfolio.setIsDefault(state)
        } catch {
            // present error
        }
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        var count = 1
    
        if portfolio.storedAddresses.count > 0 {
            count = 2
        }
        
        if isEditing {
            return count + 1
        }
        
        return count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        
        if portfolio.storedAddresses.count > 0, section == 1 {
            return portfolio.storedAddresses.count
        }
        
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! TextFieldCell
                cell.configure(text: portfolio?.alias, placeholder: "Alias", isEnabled: false, completion: setAlias)
                aliasCell = cell
                return cell
            }
            
            if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Use as Default", isOn: portfolio.isDefault, completion: setIsDefault)
                return cell
            }
        }
        
        if portfolio.storedAddresses.count > 0, section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath) as! AddressCell
            let address = portfolio.storedAddresses[indexPath.row]
            cell.configure(address: address.identifier!, alias: address.alias)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "deleteCell", for: indexPath) as! DeleteCell
        cell.configure(actionText: "Delete Portfolio")
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Portfolio"
        }
        
        if portfolio.storedAddresses.count > 0, section == 1 {
            return "Addresses"
        }
       
        return nil
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        
        if portfolio.storedAddresses.count > 0, section == 1 {
            performSegue(withIdentifier: "showAddress", sender: self)
        }
        
        let deleteSection = (portfolio.storedAddresses.count > 0) ? 2 : 1
        
        if isEditing, section == deleteSection {
            deletePortfolio()
        }
    }

}
