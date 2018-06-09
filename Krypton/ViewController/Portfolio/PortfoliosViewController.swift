//
//  PortfoliosViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

protocol PortfolioSelectorDelegate {
    func portfolioSelector(_ portfolioSelector: PortfoliosViewController, didChangeSelectedPortfolio portfolio: Portfolio?)
}

class PortfoliosViewController: UITableViewController, KryptonDaemonDelegate, PortfolioCreatorDelegate {
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private var selectedPortfolio: Portfolio?
    private let isSelector: Bool
    
    private var portfolios = [Portfolio]()
    
    // MARK: - Public Properties
    var delegate: PortfolioSelectorDelegate?
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, kryptonDaemon: KryptonDaemon, portfolioManager: PortfolioManager, selectedPortfolio: Portfolio?, isSelector: Bool) {
        self.viewFactory = viewFactory
        self.kryptonDaemon = kryptonDaemon
        self.portfolioManager = portfolioManager
        self.selectedPortfolio = selectedPortfolio
        self.isSelector = isSelector
        
        super.init(style: .grouped)
        
        title = "Portfolios"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
    }
    
    // MARK: - Customization
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        kryptonDaemon.delegate = self
        
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        kryptonDaemon.delegate = nil
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        portfolios = portfolioManager.storedPortfolios
        
        if portfolios.count == 0 {
            delegate?.portfolioSelector(self, didChangeSelectedPortfolio: nil)
            let noPortfoliosLabel = UILabel()
            noPortfoliosLabel.text = "No Portfolios."
            noPortfoliosLabel.textAlignment = .center
            tableView.backgroundView = noPortfoliosLabel
        } else {
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }
    
    @objc private func addButtonPressed() {
        let addPortfolioViewController = viewFactory.makeAddPortfolioViewController()
        addPortfolioViewController.delegate = self
        let addPortfolioNavigationController = UINavigationController(rootViewController: addPortfolioViewController)
        navigationController?.present(addPortfolioNavigationController, animated: true, completion: nil)
    }
    
    // MARK: - KryptonDaemon Delegate
    func kryptonDaemonDidUpdate(_ kryptonDaemon: KryptonDaemon) {
        updateUI()
    }
    
    // MARK: - PortfolioCreator Delegate
    func portfolioCreator(_ portfolioCreator: AddPortfolioViewController, didCreatePortfolio portfolio: Portfolio) {
        selectedPortfolio = portfolio
        delegate?.portfolioSelector(self, didChangeSelectedPortfolio: selectedPortfolio)
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return portfolios.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "PortfolioCell")
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
        let selectedPortfolio = portfolios[indexPath.row]
        
        if isSelector {
            delegate?.portfolioSelector(self, didChangeSelectedPortfolio: selectedPortfolio)
            self.navigationController?.popViewController(animated: true)
        } else {
            let portfolioDetailViewController = viewFactory.makePortfolioDetailViewController(for: selectedPortfolio)
            navigationController?.pushViewController(portfolioDetailViewController, animated: true)
        }
    }
    
}
