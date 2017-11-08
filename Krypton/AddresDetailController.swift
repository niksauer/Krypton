//
//  AddresDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AddresDetailController: UITableViewController {

    // MARK: - Public Properties
    var address: Address!
    
    // MARK: - Private Properties
    private var deleteIndexPath: IndexPath!
    
    override func viewDidLoad() {
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let folderButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_folder"), style: .plain, target: self, action: nil)
        let deleteButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_trash"), style: .plain, target: self, action: nil)
        self.toolbarItems = [deleteButton, flexibleSpacer, folderButton]
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    // MARK: - Navigation
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

    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch address {
        case let tokenAddress as TokenAddress:
            if tokenAddress.storedTokens.count > 0 {
                return 4
            } else {
                return 3
            }
        default:
            return 3
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch address {
        case let tokenAddress as TokenAddress where (section == 2 && tokenAddress.storedTokens.count > 0):
           return tokenAddress.storedTokens.count
        default:
            if section == 0 || section == 1 {
                return 2
            } else {
                return 1
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch address {
        case let tokenAddress as TokenAddress where (section == 2 && tokenAddress.storedTokens.count > 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
            let token = tokenAddress.storedTokens[indexPath.row]
            cell.textLabel?.text = token.name
            cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: token.balance, currency: token)
            return cell
        default:
            if section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! TextFieldCell
                if row == 0 {
                    cell.configure(text: address.identifier, placeholder: "Address", completion: nil)
                    cell.textField.isEnabled = false
                } else {
                    cell.configure(text: address.alias, placeholder: "Alias", completion: setAlias)
                    cell.textField.clearButtonMode = .always
                }
                return cell
            } else if section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
                if row == 0 {
                    cell.textLabel?.text = "Blockchain"
                    cell.detailTextLabel?.text = address.blockchain.name
                } else {
                    cell.textLabel?.text = "Balance"
                    cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: address.balance, currency: address.blockchain)
                }
                return cell
            } else {
                deleteIndexPath = indexPath
                let cell = tableView.dequeueReusableCell(withIdentifier: "deleteCell", for: indexPath) as! DeleteCell
                cell.configure(actionText: "Delete Address")
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch address {
        case let tokenAddress as TokenAddress where (section == 2 && tokenAddress.storedTokens.count > 0):
            return "Tokens"
        default:
            if section == 0 {
                return "Address"
            } else {
                return nil
            }
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == deleteIndexPath {
            deleteAddress()
        }
    }

}
