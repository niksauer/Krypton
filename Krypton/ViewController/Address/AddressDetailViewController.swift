//
//  AddressDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class AddressDetailViewController: UITableViewController, PortfolioSelectorDelegate {
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let address: Address
    
    private var alias: String?
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, address: Address) {
        self.viewFactory = viewFactory
        self.address = address
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
        
        tableView.register(UINib(nibName: "TextFieldCell", bundle: nil), forCellReuseIdentifier: "TextFieldCell")
        tableView.register(UINib(nibName: "DeleteCell", bundle: nil), forCellReuseIdentifier: "DeleteCell")
        tableView.register(UINib(nibName: "TokenCell", bundle: nil), forCellReuseIdentifier: "TokenCell")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let alias = alias?.trimmingCharacters(in: .whitespacesAndNewlines), alias != address.alias {
            do {
                try address.setAlias(alias)
            } catch {
                // TODO: present error
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.reloadData()
    }
    
    // MARK: - Private Methods
    private func setAlias(_ alias: String?) {
        self.alias = alias
    }
    
    private func deleteAddress() {
        do {
            try address.portfolio!.removeAddress(address: address)
            self.navigationController?.popViewController(animated: true)
        } catch {
            // TODO: present error
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
            // TODO: present error
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
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "PortfolioCell")
                cell.textLabel?.text = "Portfolio"
                cell.detailTextLabel?.text = address.portfolio?.alias
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
            if section == 2 {
                // delete section (2)
                let cell = tableView.dequeueReusableCell(withIdentifier: "DeleteCell", for: indexPath) as! DeleteCell
                cell.configure(actionText: "Delete Address")
                return cell
            }
        } else {
            if section == 1 {
                // blockchain section (1)
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "PortfolioCell")
                
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
                let cell = tableView.dequeueReusableCell(withIdentifier: "TokenCell", for: indexPath) as! TokenCell
                cell.configure(token: token, showsBalance: true)
                return cell
            }
        }
        
        // address section (0)
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldCell
        
        if row == 0 {
            cell.configure(text: address.identifier, placeholder: "Address", isEnabled: false, onChange: nil)
        }
        
        if row == 1 {
            cell.configure(text: address.alias, placeholder: "Alias", isEnabled: isEditing, onChange: setAlias)
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
        if isEditing {
            if indexPath.section == 1 {
                let portfolioSelector = viewFactory.makePortfolioSelectionViewController(selection: address.portfolio)
                portfolioSelector.delegate = self
                navigationController?.pushViewController(portfolioSelector, animated: true)
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
