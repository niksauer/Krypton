//
//  AddressDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AddressDetailController: UITableViewController, PortfolioSelectorDelegate {
    
    // MARK: - Public Properties
    var address: Address!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.reloadData()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? PortfolioTableController {
            destVC.delegate = self
            destVC.isSelector = true
            destVC.selectedPortfolio = address.portfolio
        }
    }
    
    func setAlias(_ alias: String?) {
        guard let alias = alias?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }

        do {
            try address.setAlias(alias)
        } catch {
            // present error
        }
    }
    
    func deleteAddress() {
        do {
            try address!.portfolio!.removeAddress(address: address)
            self.navigationController?.popViewController(animated: true)
        } catch {
            // present error
        }
    }

    // MARK: - PortfolioSelector Delegate
    func didChangeSelection(selection: Portfolio?) {
        guard let selection = selection else {
            return
        }
        
        do {
            try address.setPortfolio(selection)
            let portfolioCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1))
            portfolioCell?.detailTextLabel?.text = selection.alias
        } catch {
            // present error
        }
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isEditing {
            // address + portfolio + delete
            return 3
        } else {
            if let tokenAddress = address as? TokenAddress, tokenAddress.storedTokens.count > 0 {
                // address + blockchain + tokens
                return 3
            } else {
                // address + blockchain
                return 2
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isEditing {
            if section == 1 {
                // portfolio section (1)
                return 1
            }
            
            if section == 2 {
                // delete section (2)
                return 1
            }
        } else {
            if section == 1 {
                // blockchain section (1)
                return 2
            }
            
            if let tokenAddress = address as? TokenAddress, section == 2, tokenAddress.storedTokens.count > 0 {
                // token section (2)
                return tokenAddress.storedTokens.count
            }
        }
        
        // address section (0)
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        if isEditing {
            if section == 1 {
                // portfolio section (1)
                let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioCell", for: indexPath)
                cell.detailTextLabel?.text = address.portfolio?.alias
                return cell
            }
            
            if section == 2 {
                // delete section (2)
                let cell = tableView.dequeueReusableCell(withIdentifier: "deleteCell", for: indexPath) as! DeleteCell
                cell.configure(actionText: "Delete Address")
                return cell
            }
        } else {
            if section == 1 {
                // blockchain section (1)
                let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
                
                if row == 0 {
                    cell.textLabel?.text = "Blockchain"
                    cell.detailTextLabel?.text = address.blockchain.name
                }
                
                if row == 1 {
                    cell.textLabel?.text = "Balance"
                    cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: address.balance, currency: address.blockchain)
                }
                
                return cell
            }
            
            if let tokenAddress = address as? TokenAddress, section == 2, tokenAddress.storedTokens.count > 0 {
                // token section (2)
                let token = tokenAddress.storedTokens[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "tokenCell", for: indexPath) as! TokenCell
                cell.configure(token: token, showsBalance: true)
                return cell
            }
        }
        
        // address section (0)
        let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! TextFieldCell
        
        if row == 0 {
            cell.configure(text: address.identifier, placeholder: "Address", isEnabled: false, completion: nil)
        }
        
        if row == 1 {
            cell.configure(text: address.alias, placeholder: "Alias", isEnabled: isEditing, completion: setAlias)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Address"
        }
        
        if !isEditing, let tokenAddress = address as? TokenAddress, section == 2, tokenAddress.storedTokens.count > 0 {
            return "Tokens"
        }
    
        return nil
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            if indexPath.section == 1 {
                performSegue(withIdentifier: "selectPortfolio", sender: self)
            }
            
            if indexPath.section == 2 {
                deleteAddress()
            }
        } else {
            if let tokenCell = tableView.cellForRow(at: indexPath) as? TokenCell {
                tokenCell.showsBalance = !tokenCell.showsBalance
            }
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

}
