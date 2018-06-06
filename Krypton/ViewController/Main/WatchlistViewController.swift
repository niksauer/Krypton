//
//  WatchlistController.swift
//  Krypton
//
//  Created by Niklas Sauer on 30.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class WatchlistViewController: UITableViewController, TickerDaemonDelegate {
    
    // MARK: - Private Properties
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let currencyManager: CurrencyManager
    
    // MARK: - Public Properties
    var displayedCurrencies = [Currency]()
    var requiredCurrencies = [Currency]()
    var manualCurrencies = [Currency]()
    var missingCurrencies = [Currency]()

    // MARK: - Initialization
    init(portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, currencyManager: CurrencyManager) {
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        self.currencyManager = currencyManager
        
        super.init(style: .grouped)
        
        title = "Watchlist"
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tickerDaemon.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updateData), for: .valueChanged)
        
        requiredCurrencies = portfolioManager.requiredCurrencyPairs.map({ $0.base })
        manualCurrencies = portfolioManager.manualCurrencies.filter({ optionalCurrency in
            !requiredCurrencies.contains(where: { $0.isEqual(to: optionalCurrency )})
        })
    
        for currency in currencyManager.getCurrencies(of: .Crypto) {
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
    @objc private func updateData() {
        tickerDaemon.update {
            self.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - TickerDaemon Delegate
    func tickerDaemon(_ tickerDaemon: TickerDaemon, didUpdateCurrentExchangeRateForCurrencyPair currencyPair: CurrencyPair) {
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
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
        let currencyPair = CurrencyPair(base: currency, quote: portfolioManager.quoteCurrency)
        let cell = UITableViewCell(style: .default, reuseIdentifier: "TickerCell")
        cell.textLabel?.text = currencyPair.base.code
    
        if requiredCurrencies.contains(where: { $0.isEqual(to: currency) }) || manualCurrencies.contains(where: { $0.isEqual(to: currency) }) {
            if let currentExchangeRate = tickerDaemon.getCurrentExchangeRate(for: currencyPair) {
                cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: currentExchangeRate, currency: portfolioManager.quoteCurrency)
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
            portfolioManager.removeCurrency(currency)
        }
        
        if editingStyle == .insert, let index = missingCurrencies.index(where: { $0.isEqual(to: currency) }) {
            missingCurrencies.remove(at: index)
            manualCurrencies.append(currency)
            portfolioManager.addCurrency(currency)
        }
        
        tableView.reloadData()
    }
    
}
