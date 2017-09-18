//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DashboardController: UIViewController, UITabBarControllerDelegate, PortfolioManagerDelegate, TickerWatchlistDelegate, FilterDelegate {
    
    // MARK: - Private Properties
    private enum PortfolioDisplayType {
        case currentExchangeValue
        case relativeProfit
        case absoluteProfit
    }

    private var comparisonDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())! {
        didSet {
            updateUI()
        }
    }
    
    private var transactionFilter: TransactionType = .all {
        didSet {
            updateUI()
        }
    }
    
    private var portfolioDisplay: PortfolioDisplayType = .currentExchangeValue {
        didSet {
            guard let currentExchangeValue = PortfolioManager.shared.getExchangeValue(for: transactionFilter, on: Date()), let profitStats = PortfolioManager.shared.getProfitStats(for: transactionFilter, timeframe: .allTime) else {
                portfolioValueLabel.text = "???"
                return
            }
            
            switch portfolioDisplay {
            case .currentExchangeValue:
                portfolioLabel.text = "Total Portfolio Value"
                portfolioValueLabel.text = Format.getFiatFormatting(for: NSNumber(value: currentExchangeValue), fiatCurrency: PortfolioManager.shared.baseCurrency)
            case .relativeProfit:
                portfolioLabel.text = "Total Relative Profit"
                let relativeProfit = Format.relativeProfit(from: profitStats)
                portfolioValueLabel.text = Format.getNumberFormatting(for: NSNumber(value: relativeProfit)) + "%"
            case .absoluteProfit:
                portfolioLabel.text = "Total Absolute Profit"
                let absoluteProfit = Format.absoluteProfit(from: profitStats)
                portfolioValueLabel.text = Format.getFiatFormatting(for: NSNumber(value: absoluteProfit), fiatCurrency: PortfolioManager.shared.baseCurrency)
            }
        }
    }
    
    private var showsRelativeProfit = true {
        didSet {
            guard let profitStats = PortfolioManager.shared.getProfitStats(for: transactionFilter, timeframe: .sinceDate(comparisonDate)) else {
                profitValueLabel.text = "???"
                return
            }

            profitLabel.text = "Since Yesterday"
            
            if showsRelativeProfit {
                let relativeProfit = Format.relativeProfit(from: profitStats)
                profitValueLabel.text = Format.getNumberFormatting(for: NSNumber(value: relativeProfit)) + "%"
            } else {
                let absoluteProfit = Format.absoluteProfit(from: profitStats)
                profitValueLabel.text = Format.getFiatFormatting(for: NSNumber(value: absoluteProfit), fiatCurrency: PortfolioManager.shared.baseCurrency)
            }
        }
    }
    
    // Mark: - Outlets
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var portfolioLabel: UILabel!
    
    @IBOutlet weak var profitValueLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    
    @IBOutlet weak var investmentValueLabel: UILabel!
    @IBOutlet weak var investmentLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.delegate = self
        PortfolioManager.shared.delegate = self
        TickerWatchlist.delegate = self
        
        investmentLabel.text = "Total Investment"
        
        portfolioValueLabel.tag = 0
        portfolioValueLabel.isUserInteractionEnabled = true
        let portfolioValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePortfolioDisplayType))
        portfolioValueLabel.addGestureRecognizer(portfolioValueTapRecognizer)
        
        profitValueLabel.tag = 1
        profitValueLabel.isUserInteractionEnabled = true
        let profitValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleProfitType))
        profitValueLabel.addGestureRecognizer(profitValueTapRecognizer)
        
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destNavVC = segue.destination as? UINavigationController, let destVC = destNavVC.topViewController as? FilterController {
            destVC.delegate = self
            destVC.transactionType = transactionFilter
        }
    }

    // MARK: - Private Methods
    private func updateUI() {
        portfolioDisplay = { portfolioDisplay }()
        showsRelativeProfit = { showsRelativeProfit }()
        
        if let investmentValue = PortfolioManager.shared.getProfitStats(for: transactionFilter, timeframe: .allTime)?.startValue {
            investmentValueLabel.text = Format.getFiatFormatting(for: NSNumber(value: investmentValue), fiatCurrency: PortfolioManager.shared.baseCurrency)
        } else {
            investmentValueLabel.text = "???"
        }
    }
    
    // MARK: - Public Methods
    func toggleProfitType(sender: UITapGestureRecognizer) {
        showsRelativeProfit = !showsRelativeProfit
    }
    
    func togglePortfolioDisplayType(sender: UITapGestureRecognizer) {
        switch portfolioDisplay {
        case .currentExchangeValue:
            portfolioDisplay = .relativeProfit
        case .relativeProfit:
            portfolioDisplay = .absoluteProfit
        case .absoluteProfit:
            portfolioDisplay = .currentExchangeValue
        }
    }
    
    // MARK: - TabBarController Delegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
//        if let destVC = viewController as? UINavigationController, let transactionVC = destVC.topViewController as? TransactionTableController {
//            transactionVC.addresses = PortfolioManager.shared.selectedAddresses
//        }
    }
    
    // MARK: - PortfolioManager Delegate
    func didUpdatePortfolioManager() {
        updateUI()
    }
    
    // MARK: - TickerWatchlist Delegate
    func didUpdateCurrentPrice(for tradingPair: Currency.TradingPair) {
        updateUI()
    }
    
    // MARK: - Filter Delegate
    func didChangeSelectedAddresses() {
        updateUI()
    }
    
    func didChangeTransactionType(to type: TransactionType) {
        self.transactionFilter = type
    }

}
