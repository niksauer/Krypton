//
//  FilterController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class FilterController: UITableViewController {
    
    // MARK: - Public Properties
    let portfolios = PortfolioManager.shared.getPortfolios()
    let filterOptionsCount = 1
    
    var transactionType: TransactionType?

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindFromFilterPanel", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        let _ = PortfolioManager.shared.save()
    }
    
    // MARK: - Public Methods
    @IBAction func setTransactionType(_ sender: UISegmentedControl) {
        transactionType = TransactionType(rawValue: sender.selectedSegmentIndex)!
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return portfolios.count + filterOptionsCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return portfolios[section-filterOptionsCount].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "transactionTypeCell", for: indexPath)
            let transactionTypeSwitch = cell.contentView.subviews.first as! UISegmentedControl
    
            if let selectionIndex = transactionType?.rawValue {
                transactionTypeSwitch.selectedSegmentIndex = selectionIndex
            } else {
                transactionTypeSwitch.selectedSegmentIndex = 0
            }
            
            return cell
        } else {
            let address = portfolios[indexPath.section-filterOptionsCount].storedAddresses[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath)
            cell.textLabel?.text = address.address
            cell.detailTextLabel?.text = address.alias
        
            if address.isSelected {
                cell.accessoryType = .checkmark
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section != 0 else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        let address = portfolios[indexPath.section-filterOptionsCount].storedAddresses[indexPath.row]
        
        if cell.accessoryType == .checkmark {
            cell.accessoryType = .none
            address.isSelected = false
        } else {
            cell.accessoryType = .checkmark
            address.isSelected = true
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return "Transaction Type"
        }
        
        let portfolio = portfolios[section-filterOptionsCount]
        
        if let portfolioAlias = portfolio.alias {
            return portfolioAlias
        } else {
            return "Portfolio \(section-filterOptionsCount + 1)"
        }
    }

}
