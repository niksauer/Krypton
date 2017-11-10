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
    var tradingPairs = [TradingPair]()

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        TickerDaemon.delegate = self
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tradingPairs = Array(PortfolioManager.shared.storedTradingPairs).sorted(by: { $0.base.code < $1.base.code })
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tradingPairs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tradingPair = tradingPairs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "tickerCell", for: indexPath)
        cell.textLabel?.text = tradingPair.base.code
    
        if let currentPrice = tradingPair.currentPrice {
            cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: currentPrice, currency: PortfolioManager.shared.baseCurrency)
        } else {
            cell.detailTextLabel?.text = "???"
        }
        
        return cell
    }
    
    // MARK: - TickerDaemon Delegate
    func didUpdateCurrentPrice(for tradingPair: TradingPair) {
        tableView.reloadData()
    }

}
