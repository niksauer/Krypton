//
//  PortfolioDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class PortfolioDetailViewController: UITableViewController {
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let portfolio: Portfolio
    private let portfolioManager: PortfolioManager
    
    private var selectedAddress: Address?
    
    private var alias: String?
    private var isDefault: Bool
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, portfolio: Portfolio, portfolioManager: PortfolioManager) {
        self.viewFactory = viewFactory
        self.portfolio = portfolio
        self.portfolioManager = portfolioManager
        isDefault = portfolio.isDefault
        
        super.init(style: .grouped)
        
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.allowsSelectionDuringEditing = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "TextFieldCell", bundle: nil), forCellReuseIdentifier: "TextFieldCell")
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: "SwitchCell")
        tableView.register(UINib(nibName: "DeleteCell", bundle: nil), forCellReuseIdentifier: "DeleteCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let alias = alias?.trimmingCharacters(in: .whitespacesAndNewlines), !alias.isEmpty, alias != portfolio.alias {
            do {
                try portfolio.setAlias(alias)
            } catch {
                // TODO: present error
            }
        }

        if isDefault != portfolio.isDefault {
            do {
                try portfolio.setIsDefault(isDefault)
            } catch {
                // TODO: present error
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        let deleteSection = IndexSet(integer: (portfolio.storedAddresses.count > 0) ? 2 : 1)
        
        if isEditing {
            tableView.insertSections(deleteSection, with: .top)
        } else {
            tableView.deleteSections(deleteSection, with: .top)
        }
        
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
    }

    // MARK: - Private Methods
    private func deletePortfolio() {
        do {
            try portfolioManager.removePortfolio(portfolio)
            self.navigationController?.popViewController(animated: true)
        } catch {
            // TODO: present error
        }
    }
    
    private func didChangeAlias(_ alias: String?) {
        self.alias = alias
    }
    
    private func didChangeIsDefault(_ isDefault: Bool) {
        self.isDefault = isDefault
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
        switch section {
        case 0:
            return 2
        case 1 where portfolio.storedAddresses.count > 0:
            return portfolio.storedAddresses.count
        default:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            switch row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldCell
                cell.configure(text: portfolio.alias, placeholder: "Alias", isEnabled: isEditing, onChange: didChangeAlias)
                cell.isEnabledClearButtonMode = .always
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Use as default", isOn: portfolio.isDefault, onChange: didChangeIsDefault)
                return cell
            default:
                fatalError()
            }
        case 1 where portfolio.storedAddresses.count > 0:
            let address = portfolio.storedAddresses[indexPath.row]
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "AddressCell")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = address.identifier
            cell.detailTextLabel?.text = address.alias
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DeleteCell", for: indexPath) as! DeleteCell
            cell.configure(actionText: "Delete Portfolio")
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Portfolio"
        case 1 where portfolio.storedAddresses.count > 0:
            return "Addresses"
        default:
            return nil
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        
        switch section {
        case 1 where portfolio.storedAddresses.count > 0:
            let selectedAddress = portfolio.storedAddresses[indexPath.row]
            let addressDetailViewController = viewFactory.makeAddressDetailViewController(for: selectedAddress)
            navigationController?.pushViewController(addressDetailViewController, animated: true)
        case (portfolio.storedAddresses.count > 0) ? 2 : 1 where isEditing:
            deletePortfolio()
        default:
            break
        }
    }

}
