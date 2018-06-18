//
//  AccountsViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 01.11.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import ToolKit

class AccountsViewController: UITableViewController, KryptonDaemonDelegate, TickerDaemonDelegate {

    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let currencyFormatter: CurrencyFormatter
    private let taxAdviser: TaxAdviser
    
    private var portfolios = [Portfolio]()
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, kryptonDaemon: KryptonDaemon, portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, currencyFormatter: CurrencyFormatter, taxAdviser: TaxAdviser) {
        self.viewFactory = viewFactory
        self.kryptonDaemon = kryptonDaemon
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        self.currencyFormatter = currencyFormatter
        self.taxAdviser = taxAdviser
        
        super.init(style: .grouped)
        
        title = "Accounts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_settings"), style: .plain, target: self, action: #selector(settingsButtonPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "SectionHeaderCell", bundle: nil), forCellReuseIdentifier: "SectionHeaderCell")
        tableView.register(DetailCell.self, forCellReuseIdentifier: "DetailCell")
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updateData), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(true, animated: true)
        
        kryptonDaemon.delegate = self
        tickerDaemon.delegate = self
        
        updatePortfolios()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        kryptonDaemon.delegate = nil
        tickerDaemon.delegate = nil
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
    }
    
    @objc private func updateData() {
        portfolioManager.update {
            self.refreshControl?.endRefreshing()
        }
    }
    
    private func updatePortfolios() {
        portfolios = portfolioManager.storedPortfolios.filter { $0.storedAddresses.count > 0 }.sorted(by: { $0.alias! < $1.alias! })
    }
    
    @objc private func settingsButtonPressed() {
        let settingsViewController = viewFactory.makeSettingsViewController()
        let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController?.present(settingsNavigationController, animated: true, completion: nil)
    }
    
    @objc private func addButtonPressed() {
        let addAddressViewController = viewFactory.makeAddAdressViewController()
        let addAddressNavigationController = UINavigationController(rootViewController: addAddressViewController)
        navigationController?.present(addAddressNavigationController, animated: true, completion: nil)
    }
    
    private func getAddress(for indexPath: IndexPath) -> Address? {
        return portfolios[indexPath.section].storedAddresses.sorted(by: { portfolioManager.getAlias(for: $0.identifier!) < portfolioManager.getAlias(for: $1.identifier!) })[indexPath.row-1]
    }
    
    // MARK: Collapse Helpers
    private func getHeaderIndices() -> [Int] {
        var index = 0
        var indices = [Int]()
        
        for portfolio in portfolios {
            indices.append(index)
            index = index + portfolio.storedAddresses.count + 1
        }
        
        return indices
    }
    
    private func getSectionIndex(_ row: Int) -> Int {
        let indices = getHeaderIndices()
        
        for i in 0..<indices.count {
            if i == indices.count - 1 || row < indices[i + 1] {
                return i
            }
        }
        
        return -1
    }
    
    private func getRowIndex(_ row: Int) -> Int {
        var index = row
        let indices = getHeaderIndices()
        
        for i in 0..<indices.count {
            if i == indices.count - 1 || row < indices[i + 1] {
                index -= indices[i]
                break
            }
        }
        
        return index
    }
    
    // MARK: - KryptonDaemon Delegate
    func kryptonDaemonDidUpdate(_ kryptonDaemon: KryptonDaemon) {
        updatePortfolios()
        updateUI()
    }
    
    // MARK: - TickerDaemon Delegate
    func tickerDaemon(_ tickerDaemon: TickerDaemon, didUpdateCurrentExchangeRateForCurrencyPair currencyPair: CurrencyPair) {
        updateUI()
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return portfolios.reduce(portfolios.count, { $0 + $1.storedAddresses.count })
        default:
            fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "InfoCell")
            cell.accessoryType = .disclosureIndicator
            
            switch row {
            case 0:
                cell.textLabel?.text = "Dashboard"
            case 1:
                cell.textLabel?.text = "Watchlist"
            default:
                fatalError()
            }
            
            return cell
        case 1:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "AllTransactionsCell")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "All Transactions"
            return cell
        case 2:
            let section = getSectionIndex(indexPath.row)
            let row = getRowIndex(indexPath.row)
            
            switch row {
            case 0:
                let portfolio = portfolios[section]
                let cell = tableView.dequeueReusableCell(withIdentifier: "SectionHeaderCell", for: indexPath) as! SectionHeaderCell
                cell.isCollapsed = portfolio.isCollapsed
                cell.sectionLabel.text = portfolio.alias?.uppercased()
                
                if let exchangeValue = taxAdviser.getTotalExchangeValue(for: portfolio) {
                    cell.detailLabel.text = currencyFormatter.getFormatting(for: exchangeValue, currency: portfolio.quoteCurrency)
                } else {
                    cell.detailLabel.text = nil
                }
                
                return cell
            default:
                guard let address = getAddress(for: IndexPath(row: row, section: section)) else {
                    fatalError()
                }
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell") as! DetailCell
                cell.label.text = portfolioManager.getAlias(for: address.identifier!)
                cell.detailLabel.text = currencyFormatter.getFormatting(for: address.balance, currency: address.blockchain, maxDigits: 2)
                cell.accessoryType = .detailDisclosureButton
                return cell
            }
        default:
            fatalError()
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 2 else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        let section = getSectionIndex(indexPath.row)
        let row = getRowIndex(indexPath.row)
        
        if row == 0 {
            // sectionHeader
            return super.tableView(tableView, heightForRowAt: indexPath)
        } else {
            // sectionItem
            return portfolios[section].isCollapsed ? 0 : 44
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                let dashboardViewController = viewFactory.makeDashboardViewController()
                navigationController?.pushViewController(dashboardViewController, animated: true)
            }
            if row == 1 {
                let watchlistViewController = viewFactory.makeWatchlistViewController()
                navigationController?.pushViewController(watchlistViewController, animated: true)
            }
        } else if section == 1 {
            if row == 0 {
                let transactionsViewController = viewFactory.makeTransactionsViewController(for: portfolioManager.storedAddresses)
                transactionsViewController.title = "All Transactions"
                navigationController?.pushViewController(transactionsViewController, animated: true)
            }
        } else if section == 2 {
            let section = getSectionIndex(indexPath.row)
            let row = getRowIndex(indexPath.row)
        
            if row == 0 {
                // toggle collapse
                portfolios[section].isCollapsed = !portfolios[section].isCollapsed
            
                let cell = tableView.cellForRow(at: indexPath) as! SectionHeaderCell
                cell.isCollapsed = portfolios[section].isCollapsed
                
                let indices = getHeaderIndices()
                
                let start = indices[section]
                let end = start + portfolios[section].storedAddresses.count
        
                tableView.beginUpdates()
                
                for i in start ..< end + 1 {
                    let indexPath = IndexPath(row: i, section: 2)
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                
                tableView.endUpdates()
            } else {
                guard let address = getAddress(for: IndexPath(row: row, section: section)) else {
                    fatalError()
                }
                
                let transactionsViewController = viewFactory.makeTransactionsViewController(for: [address])
                transactionsViewController.title = portfolioManager.getAlias(for: address.identifier!)
                navigationController?.pushViewController(transactionsViewController, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard indexPath.section >= 2 else {
            return
        }
        
        let section = getSectionIndex(indexPath.row)
        let row = getRowIndex(indexPath.row)
        
        guard let address = getAddress(for: IndexPath(row: row, section: section)) else {
            fatalError()
        }
        
        let addressDetailViewController = viewFactory.makeAddressDetailViewController(for: address)
        navigationController?.pushViewController(addressDetailViewController, animated: true)
    }
        
}
