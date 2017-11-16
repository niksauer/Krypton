//
//  WatchlistController.swift
//  Krypton
//
//  Created by Niklas Sauer on 30.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class WatchlistController: UITableViewController, TickerDaemonDelegate {
    
    // MARK: - Public Properties
    var displayedCurrencies = [Currency]()
    var requiredCurrencies = [Currency]()
    var manualCurrencies = [Currency]()
    var missingCurrencies = [Currency]()

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        TickerDaemon.delegate = self
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(updateTicker), for: .valueChanged)
        
        
        requiredCurrencies = PortfolioManager.shared.requiredCurrencyPairs.map({ $0.base })
        manualCurrencies = PortfolioManager.shared.manualCurrencies.filter({ optionalCurrency in
            !requiredCurrencies.contains(where: { $0.isEqual(to: optionalCurrency )})
        })
    
        for currency in CurrencyManager.getCurrencies(of: .Crypto) {
            guard !requiredCurrencies.contains(where: { $0.isEqual(to: currency) }) && !manualCurrencies.contains(where: { $0.isEqual(to: currency) }) else {
                continue
            }
            
            missingCurrencies.append(currency)
        }
   
        displayedCurrencies = requiredCurrencies + manualCurrencies
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        var indexPaths = [IndexPath]()
        
        for index in 0..<missingCurrencies.count {
            indexPaths.append(IndexPath(row: requiredCurrencies.count + manualCurrencies.count + index, section: 0))
        }
        
        if isEditing {
            displayedCurrencies = requiredCurrencies + manualCurrencies + missingCurrencies
            tableView.insertRows(at: indexPaths, with: .top)
        } else {
            displayedCurrencies = requiredCurrencies + manualCurrencies
            tableView.deleteRows(at: indexPaths, with: .top)
        }
    }
    
    // MARK: - Private Methods
    @objc private func updateTicker() {
        TickerDaemon.update {
            self.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isEditing {
            return requiredCurrencies.count + manualCurrencies.count + missingCurrencies.count
        } else {
            return requiredCurrencies.count + manualCurrencies.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currency = displayedCurrencies[indexPath.row]
        let currencyPair = CurrencyPair(base: currency, quote: PortfolioManager.shared.quoteCurrency)
        let cell = tableView.dequeueReusableCell(withIdentifier: "tickerCell", for: indexPath)
        cell.textLabel?.text = currencyPair.base.code
    
        if requiredCurrencies.contains(where: { $0.isEqual(to: currency) }) || manualCurrencies.contains(where: { $0.isEqual(to: currency) }) {
            if let currentRate = currencyPair.currentRate {
                cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: currentRate, currency: PortfolioManager.shared.quoteCurrency)
            } else {
                cell.detailTextLabel?.text = "???"
            }
        } else {
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let currency = displayedCurrencies[indexPath.row]
        return manualCurrencies.contains(where: { $0.isEqual(to: currency) }) || missingCurrencies.contains(where: { $0.isEqual(to: currency) })
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        let currency = displayedCurrencies[indexPath.row]
        
        if manualCurrencies.contains(where: { $0.isEqual(to: currency) }) {
            return .delete
        } else if missingCurrencies.contains(where: { $0.isEqual(to: currency)}) {
            return .insert
        } else {
            return .none
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let currency = displayedCurrencies[indexPath.row]

        if editingStyle == .delete, let index = manualCurrencies.index(where: { $0.isEqual(to: currency) }) {
            manualCurrencies.remove(at: index)
            missingCurrencies.append(currency)
            PortfolioManager.shared.removeCurrency(currency)
        }
        
        if editingStyle == .insert, let index = missingCurrencies.index(where: { $0.isEqual(to: currency) }) {
            missingCurrencies.remove(at: index)
            manualCurrencies.append(currency)
            PortfolioManager.shared.addCurrency(currency)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - TickerDaemon Delegate
    func didUpdateCurrentPrice(for currencyPair: CurrencyPair) {
        tableView.reloadData()
    }

}
