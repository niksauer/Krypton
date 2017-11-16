//
//  PortfolioTableController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

protocol PortfolioSelectorDelegate {
    func didChangeSelection(selection: Portfolio?)
}

class PortfolioTableController: UITableViewController, PortfolioManagerDelegate, PortfolioCreatorDelegate  {
    
    // MARK: - Private Properties
    private var portfolios = [Portfolio]()
    
    // MARK: - Public Properties
    var isSelector = false
    var delegate: PortfolioSelectorDelegate?
    var selectedPortfolio: Portfolio?
    
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PortfolioManager.shared.delegate = self
        updateUI()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    
        if let destVC = segue.destination as? PortfolioDetailController {
            destVC.portfolio = selectedPortfolio
        }
        
        if let destVC = (segue.destination as? UINavigationController)?.childViewControllers.first as? AddPortfolioController {
            destVC.delegate = self
        }
    }
    
    // MARK: - Public Methods
    func updateUI() {
        portfolios = PortfolioManager.shared.storedPortfolios
        
        if portfolios.count == 0 {
            delegate?.didChangeSelection(selection: nil)
            let noPortfoliosLabel = UILabel()
            noPortfoliosLabel.text = "No Portfolios."
            noPortfoliosLabel.textAlignment = .center
            tableView.backgroundView = noPortfoliosLabel
        } else {
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
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
            } else {
                cell.accessoryType = .none
            }
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPortfolio = portfolios[indexPath.row]
        
        if isSelector {
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
        updateUI()
    }

    // MARK: - PortfolioCreator Delegate
    func shouldCreatePortfolio(alias: String, isDefault: Bool) {
        do {
            let portfolio = try PortfolioManager.shared.addPortfolio(alias: alias, quoteCurrency: PortfolioManager.shared.quoteCurrency)
            try portfolio.setIsDefault(isDefault)
            selectedPortfolio = portfolio
            delegate?.didChangeSelection(selection: portfolio)
            updateUI()
        } catch {
            // present error
        }
    }
    
}
