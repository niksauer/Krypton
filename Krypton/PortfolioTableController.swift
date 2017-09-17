//
//  PortfolioTableController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class PortfolioTableController: UITableViewController, PortfolioManagerDelegate {
    
    // MARK: - Public Properties
    var isSelector = false
    var delegate: PortfolioSelectorDelegate?
    var selectedPortfolio: Portfolio?
    
    // MARK: - Private Properties
    private var portfolios = PortfolioManager.shared.getPortfolios()
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        PortfolioManager.shared.delegate = self
    }

    // MARK: - Navigation
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
        
        if editing {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPortfolio))
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? PortfolioDetailController {
            destVC.portfolio = selectedPortfolio
        }
    }
    
    // MARK: - Public Methods
    func addPortfolio() {
        performSegue(withIdentifier: "addPortfolio", sender: self)
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return portfolios.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioCell", for: indexPath)
        let portfolio = portfolios[indexPath.row]
        
        cell.textLabel?.text = portfolio.alias
        
        if isSelector {
            if portfolio == selectedPortfolio {
                cell.accessoryType = .checkmark
            }
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPortfolio = portfolios[indexPath.row]
        
        if isSelector, !tableView.isEditing {
            delegate?.didChangeSelection(selection: selectedPortfolio)
            self.navigationController?.popViewController(animated: true)
        } else {
            performSegue(withIdentifier: "showPortfolio", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    // MARK: - PortfolioManager Delegate
    func didUpdatePortfolioManager() {
        portfolios = PortfolioManager.shared.getPortfolios()
        if portfolios.count == 0 {
            delegate?.didChangeSelection(selection: nil)
        }
        tableView.reloadData()
    }

}

protocol PortfolioSelectorDelegate {
    func didChangeSelection(selection: Portfolio?)
}