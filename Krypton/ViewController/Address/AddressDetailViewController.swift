//
//  AddressDetailViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import ToolKit

class AddressDetailViewController: UITableViewController, PortfolioSelectorDelegate {
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let address: Address
    private let tokens: [Token]?
    private let currencyFormatter: CurrencyFormatter
    private let taxAdviser: TaxAdviser
    private var alias: String?
    
    private var isDeleted = false
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, address: Address, currencyFormatter: CurrencyFormatter, taxAdviser: TaxAdviser) {
        self.viewFactory = viewFactory
        self.address = address
        
        if let tokenAddress = address as? TokenAddress {
            tokens = tokenAddress.storedTokens.sorted(by: { $0.name < $1.name })
        } else {
            tokens = nil
        }
        
        self.currencyFormatter = currencyFormatter
        self.taxAdviser = taxAdviser
        alias = address.alias
        
        super.init(style: .grouped)
    
        navigationItem.rightBarButtonItem = editButtonItem
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        tableView.allowsSelectionDuringEditing = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(DeleteCell.self, forCellReuseIdentifier: "DeleteCell")
        tableView.register(TokenCell.self, forCellReuseIdentifier: "TokenCell")
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        guard !isDeleted else {
            return
        }
        
        if !isEditing {
            do {
                try address.setAlias(alias)
            } catch {
                displayAlert(title: "Error", message: "Failed to set new alias of address: \(error)", completion: nil)
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Private Methods
    @objc private func didChangeAlias(_ sender: UITextField) {
        self.alias = sender.text
    }
    
    private func deleteAddress() {
        do {
            try address.portfolio!.removeAddress(address: address)
            isDeleted = true
            self.navigationController?.popViewController(animated: true)
        } catch {
            displayAlert(title: "Error", message: "Failed to delete address: \(error)", completion: nil)
        }
    }

    // MARK: - PortfolioSelector Delegate
    func portfolioSelector(_ portfolioSelector: PortfoliosViewController, didChangeSelectedPortfolio portfolio: Portfolio?) {
        guard let selection = portfolio else {
            return
        }
        
        do {
            try address.setPortfolio(selection)
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
        } catch {
            displayAlert(title: "Error", message: "Failed to change portfolio of address: \(error)", completion: nil)
        }
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isEditing {
            // address + portfolio + delete
            return 3
        } else {
            if let tokens = tokens, tokens.count > 0 {
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
            if section == 0 {
                // address section (0)
                return 2
            }
            
            if section == 1 {
                // portfolio section (1)
                return 1
            }
            
            if section == 2 {
                // delete section (2)
                return 1
            }
        } else {
            if section == 0 {
                // address section (0)
                return address.alias != nil ? 2 : 1
            }
            
            if section == 1 {
                // blockchain section (1)
                return 2
            }
            
            if section == 2, let tokens = tokens {
                // token section (2)
                return tokens.count
            }
        }
        
        fatalError()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        if isEditing {
            if section == 1 {
                // portfolio section (1)
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "PortfolioCell")
                cell.textLabel?.text = "Portfolio"
                cell.detailTextLabel?.text = address.portfolio?.alias
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
            if section == 2 {
                // delete section (2)
                let cell = tableView.dequeueReusableCell(withIdentifier: "DeleteCell", for: indexPath) as! DeleteCell
                cell.label.text = "Delete Address"
                return cell
            }
        } else {
            if section == 1 {
                // blockchain section (1)
                switch row {
                case 0:
                    let cell = UITableViewCell(style: .value1, reuseIdentifier: "PortfolioCell")
                    cell.textLabel?.text = "Blockchain"
                    cell.detailTextLabel?.text = address.blockchain.name
                    cell.selectionStyle = .none
                    return cell
                case 1:
                    let cell = UITableViewCell(style: .value1, reuseIdentifier: "BalanceCell")
                    cell.textLabel?.text = "Balance"
                    cell.detailTextLabel?.text = currencyFormatter.getFormatting(for: address.balance, currency: address.blockchain)
                    cell.selectionStyle = .none
                    return cell
                default:
                    fatalError()
                }
            }
            
            if section == 2, let tokens = tokens {
                // token section (2)
                let token = tokens[indexPath.row]
                let cell = TokenCell(token: token, currencyFormatter: currencyFormatter, taxAdviser: taxAdviser, reuseIdentifier: "TokenCell")
//                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }
        
        // address section (0)
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldCell
        
        if row == 0 {
            cell.textField.text = address.identifier
            cell.textField.placeholder = "Address"
            cell.isEnabled = false
        }
        
        if row == 1 {
            cell.textField.text = alias
            cell.textField.placeholder = "Alias"
            cell.isEnabled = isEditing
            cell.textField.addTarget(self, action: #selector(didChangeAlias(_:)), for: .editingChanged)
            cell.isEnabledClearButtonMode = .always
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
        let section = indexPath.section
        
        if isEditing {
            if section == 1 {
                let portfolioSelector = viewFactory.makePortfolioSelectorViewController(selection: address.portfolio)
                portfolioSelector.delegate = self
                navigationController?.pushViewController(portfolioSelector, animated: true)
            }
            
            if section == 2 {
                deleteAddress()
            }
        } else {
            if let tokenCell = tableView.cellForRow(at: indexPath) as? TokenCell {
                tokenCell.showsFirstDetailValue = !tokenCell.showsFirstDetailValue
            }
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}
