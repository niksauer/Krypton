//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DashboardController: UIViewController, PortfolioManagerDelegate, TickerWatchlistDelegate, FilterDelegate {
    
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
                portfolioValueLabel.text = Format.getCurrencyFormatting(for: currentExchangeValue, currency: PortfolioManager.shared.baseCurrency)
            case .relativeProfit:
                portfolioLabel.text = "Total Relative Profit"
                let relativeProfit = Format.getRelativeProfit(from: profitStats)
                portfolioValueLabel.text = Format.getNumberFormatting(for: NSNumber(value: relativeProfit)) + "%"
            case .absoluteProfit:
                portfolioLabel.text = "Total Absolute Profit"
                let absoluteProfit = Format.getAbsoluteProfit(from: profitStats)
                portfolioValueLabel.text = Format.getCurrencyFormatting(for: absoluteProfit, currency: PortfolioManager.shared.baseCurrency)
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
                let relativeProfit = Format.getRelativeProfit(from: profitStats)
                profitValueLabel.text = Format.getNumberFormatting(for: NSNumber(value: relativeProfit)) + "%"
            } else {
                let absoluteProfit = Format.getAbsoluteProfit(from: profitStats)
                profitValueLabel.text = Format.getCurrencyFormatting(for: absoluteProfit, currency: PortfolioManager.shared.baseCurrency)
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
        
        portfolioValueLabel.tag = 0
        portfolioValueLabel.isUserInteractionEnabled = true
        let portfolioValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePortfolioDisplayType))
        portfolioValueLabel.addGestureRecognizer(portfolioValueTapRecognizer)
        
        profitValueLabel.tag = 1
        profitValueLabel.isUserInteractionEnabled = true
        let profitValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleProfitType))
        profitValueLabel.addGestureRecognizer(profitValueTapRecognizer)
        
        investmentLabel.text = "Total Investment"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PortfolioManager.shared.delegate = self
        TickerWatchlist.delegate = self
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
            investmentValueLabel.text = Format.getCurrencyFormatting(for: investmentValue, currency: PortfolioManager.shared.baseCurrency)
        } else {
            investmentValueLabel.text = "???"
        }
    }
    
    // MARK: - Public Methods
    @objc func toggleProfitType(sender: UITapGestureRecognizer) {
        showsRelativeProfit = !showsRelativeProfit
    }
    
    @objc func togglePortfolioDisplayType(sender: UITapGestureRecognizer) {
        switch portfolioDisplay {
        case .currentExchangeValue:
            portfolioDisplay = .relativeProfit
        case .relativeProfit:
            portfolioDisplay = .absoluteProfit
        case .absoluteProfit:
            portfolioDisplay = .currentExchangeValue
        }
    }
    
    // MARK: - PortfolioManager Delegate
    func didUpdatePortfolioManager() {
        updateUI()
    }
    
    // MARK: - TickerWatchlist Delegate
    func didUpdateCurrentPrice(for tradingPair: TradingPair) {
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
