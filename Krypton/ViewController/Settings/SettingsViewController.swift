//
//  SettingsController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, KryptonDaemonDelegate, CurrencySelectorDelegate {
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, kryptonDaemon: KryptonDaemon, portfolioManager: PortfolioManager) {
        self.viewFactory = viewFactory
        self.kryptonDaemon = kryptonDaemon
        self.portfolioManager = portfolioManager
        
        super.init(style: .grouped)
        
        title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        kryptonDaemon.delegate = self
    }
    
    // MARK: - Private Methods
    @IBAction private func doneButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - KryptonDaemon Delegate
    func kryptonDaemonDidUpdate(_ kryptonService: KryptonDaemon) {

    }
    
    // MARK: - CurrencySelector Delegate
    func currencySelector(_ currencySelector: CurrencySelectorViewController, didChangeSelectedCurrency currency: Currency) {
        do {
            try portfolioManager.setQuoteCurrency(currency)
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        } catch {
            // TODO: present error
        }
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            switch row {
            case 0:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
                cell.textLabel?.text = "Quote Currency"
                cell.detailTextLabel?.text = portfolioManager.quoteCurrency.code
                cell.accessoryType = .disclosureIndicator
                return cell
            default:
                fatalError()
            }
        case 1:
            switch row {
            case 0:
                let cell = UITableViewCell(style: .default, reuseIdentifier: "InfoCell")
                cell.textLabel?.text = "Manage Portfolios"
                cell.accessoryType = .disclosureIndicator
                return cell
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }

    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            switch row {
            case 0:
                let quoteCurrencySelector = viewFactory.makeCurrencySelector(type: .Fiat, selection: portfolioManager.quoteCurrency)
                quoteCurrencySelector.title = "Quote Currency"
                quoteCurrencySelector.delegate = self
                navigationController?.pushViewController(quoteCurrencySelector, animated: true)
            default:
                fatalError()
            }
        case 1:
            switch row {
            case 0:
                let portfoliosViewController = viewFactory.makePortfoliosViewController()
                navigationController?.pushViewController(portfoliosViewController, animated: true)
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
    
}
