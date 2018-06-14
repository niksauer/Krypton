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
    private let currencyFormatter: CurrencyFormatter
    
    // MARK: - Public Properties
    private var requiredCurrencies: [Currency] {
        return portfolioManager.requiredCurrencyPairs.map({ $0.base })
    }
    
    private var manualCurrencies: [Currency] {
        return portfolioManager.manualCurrencies.filter({ optionalCurrency in
            !requiredCurrencies.contains(where: { $0.isEqual(to: optionalCurrency )})
        })
    }
    
    private var missingCurrencies: [Currency] {
        var missingCurrencies = [Currency]()
        
        for currency in currencyManager.getCurrencies(type: .Crypto) {
            guard !requiredCurrencies.contains(where: { $0.isEqual(to: currency) }) && !manualCurrencies.contains(where: { $0.isEqual(to: currency) }) else {
                continue
            }
            
            missingCurrencies.append(currency)
        }
        
        return missingCurrencies.sorted(by: { $0.code < $1.code })
    }
    
    private var displayedCurrencies: [Currency] {
        var displayedCurrencies = requiredCurrencies + manualCurrencies
        displayedCurrencies = displayedCurrencies.sorted(by: { $0.code < $1.code })
        
        if isEditing {
            displayedCurrencies = displayedCurrencies + missingCurrencies
            return displayedCurrencies
        } else {
            return displayedCurrencies
        }
    }

    // MARK: - Initialization
    init(portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, currencyManager: CurrencyManager, currencyFormatter: CurrencyFormatter) {
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        self.currencyManager = currencyManager
        self.currencyFormatter = currencyFormatter
        
        super.init(style: .grouped)
        
        title = "Watchlist"
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.allowsSelection = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updateData), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tickerDaemon.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tickerDaemon.delegate = nil
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        var missingCurrenciesIndexPaths = [IndexPath]()

        for index in 0..<missingCurrencies.count {
            missingCurrenciesIndexPaths.append(IndexPath(row: requiredCurrencies.count + manualCurrencies.count + index, section: 0))
        }

        if isEditing {
            tableView.insertRows(at: missingCurrenciesIndexPaths, with: .top)
        } else {
            tableView.deleteRows(at: missingCurrenciesIndexPaths, with: .top)
        }
    }
    
    // MARK: - Private Methods
    @objc private func updateData() {
        tickerDaemon.update { error in
            self.refreshControl?.endRefreshing()
            
            guard error == nil else {
                self.displayAlert(title: "Error", message: "Failed to update data: \(error!)", completion: nil)
                return
            }
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
        return displayedCurrencies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currency = displayedCurrencies[indexPath.row]
        let currencyPair = CurrencyPair(base: currency, quote: portfolioManager.quoteCurrency)
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "TickerCell")
        cell.textLabel?.text = currencyPair.base.code
    
        if requiredCurrencies.contains(where: { $0.isEqual(to: currency) }) || manualCurrencies.contains(where: { $0.isEqual(to: currency) }) {
            if let currentExchangeRate = tickerDaemon.getCurrentExchangeRate(for: currencyPair) {
                cell.detailTextLabel?.text = currencyFormatter.getCurrencyFormatting(for: currentExchangeRate, currency: portfolioManager.quoteCurrency)
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
        guard let currency = displayedCurrencies[safe: indexPath.row] else {
            return false
        }
        
        return !requiredCurrencies.contains(where: { $0.isEqual(to: currency)})
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

        switch editingStyle {
        case .delete:
            portfolioManager.removeCurrency(currency)
        case .insert:
            portfolioManager.addCurrency(currency)
        case .none:
            break
        }

        tableView.reloadData()
    }
    
}
