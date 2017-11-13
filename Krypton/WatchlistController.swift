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
    var optionalCurrencies = [Currency]()
    var missingCurrencies = [Currency]()

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        TickerDaemon.delegate = self
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        requiredCurrencies = PortfolioManager.shared.requiredCurrencyPairs.map({ $0.base })
        optionalCurrencies = PortfolioManager.shared.optionalCurrencies.filter({ optionalCurrency in
            !requiredCurrencies.contains(where: { $0.isEqual(to: optionalCurrency )})
        })
    
        for currency in CurrencyManager.getCurrencies(of: .Crypto) {
            guard !requiredCurrencies.contains(where: { $0.isEqual(to: currency) }) && !optionalCurrencies.contains(where: { $0.isEqual(to: currency) }) else {
                continue
            }
            
            missingCurrencies.append(currency)
        }
   
        displayedCurrencies = requiredCurrencies + optionalCurrencies
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        var indexPaths = [IndexPath]()
        
        for index in 0..<missingCurrencies.count {
            indexPaths.append(IndexPath(row: requiredCurrencies.count + optionalCurrencies.count + index, section: 0))
        }
        
        if isEditing {
            displayedCurrencies = requiredCurrencies + optionalCurrencies + missingCurrencies
            tableView.insertRows(at: indexPaths, with: .top)
        } else {
            displayedCurrencies = requiredCurrencies + optionalCurrencies
            tableView.deleteRows(at: indexPaths, with: .top)
        }
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isEditing {
            return requiredCurrencies.count + optionalCurrencies.count + missingCurrencies.count
        } else {
            return requiredCurrencies.count + optionalCurrencies.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currency = displayedCurrencies[indexPath.row]
        let currencyPair = CurrencyPair(base: currency, quote: PortfolioManager.shared.quoteCurrency)
        let cell = tableView.dequeueReusableCell(withIdentifier: "tickerCell", for: indexPath)
        cell.textLabel?.text = currencyPair.base.code
    
        if requiredCurrencies.contains(where: { $0.isEqual(to: currency) }) || optionalCurrencies.contains(where: { $0.isEqual(to: currency) }) {
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
        return optionalCurrencies.contains(where: { $0.isEqual(to: currency) }) || missingCurrencies.contains(where: { $0.isEqual(to: currency) })
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        let currency = displayedCurrencies[indexPath.row]
        
        if optionalCurrencies.contains(where: { $0.isEqual(to: currency) }) {
            return .delete
        } else if missingCurrencies.contains(where: { $0.isEqual(to: currency)}) {
            return .insert
        } else {
            return .none
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let currency = displayedCurrencies[indexPath.row]

        if editingStyle == .delete, let index = optionalCurrencies.index(where: { $0.isEqual(to: currency) }) {
            optionalCurrencies.remove(at: index)
            missingCurrencies.append(currency)
            PortfolioManager.shared.removeCurrency(currency)
        }
        
        if editingStyle == .insert, let index = missingCurrencies.index(where: { $0.isEqual(to: currency) }) {
            missingCurrencies.remove(at: index)
            optionalCurrencies.append(currency)
            PortfolioManager.shared.addCurrency(currency)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - TickerDaemon Delegate
    func didUpdateCurrentPrice(for currencyPair: CurrencyPair) {
        tableView.reloadData()
    }

}
