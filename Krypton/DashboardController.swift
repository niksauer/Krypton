//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DashboardController: UIViewController, PortfolioManagerDelegate, TickerDaemonDelegate, FilterDelegate {
    
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
    
    private var filter = Filter() {
        didSet {
            updateUI()
        }
    }
    
    private var portfolioDisplay: PortfolioDisplayType = .currentExchangeValue {
        didSet {
            guard let currentExchangeValue = PortfolioManager.shared.getExchangeValue(for: filter.transactionType, on: Date()), let profitStats = PortfolioManager.shared.getProfitStats(for: filter.transactionType, timeframe: .allTime) else {
                portfolioValueLabel.text = "???"
                return
            }
            
            switch portfolioDisplay {
            case .currentExchangeValue:
                portfolioLabel.text = "Total Portfolio Value"
                portfolioValueLabel.text = Format.getCurrencyFormatting(for: currentExchangeValue, currency: PortfolioManager.shared.baseCurrency)
            case .relativeProfit:
                portfolioLabel.text = "Total Relative Profit"
                portfolioValueLabel.text = Format.getRelativeProfitFormatting(from: profitStats)
            case .absoluteProfit:
                portfolioLabel.text = "Total Absolute Profit"
                portfolioValueLabel.text = Format.getAbsoluteProfitFormatting(from: profitStats, currency: PortfolioManager.shared.baseCurrency)
            }
        }
    }
    
    private var showsRelativeProfit: Bool = true {
        didSet {
            guard let profitStats = PortfolioManager.shared.getProfitStats(for: filter.transactionType, timeframe: .sinceDate(comparisonDate)) else {
                profitValueLabel.text = "???"
                return
            }

            profitLabel.text = "Since Yesterday"
            
            if showsRelativeProfit {
                profitValueLabel.text = Format.getRelativeProfitFormatting(from: profitStats)
            } else {
                profitValueLabel.text = Format.getAbsoluteProfitFormatting(from: profitStats, currency: PortfolioManager.shared.baseCurrency)
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
        investmentLabel.text = "Total Investment"
        
        portfolioValueLabel.tag = 0
        portfolioValueLabel.isUserInteractionEnabled = true
        let portfolioValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePortfolioDisplayType))
        portfolioValueLabel.addGestureRecognizer(portfolioValueTapRecognizer)
        
        profitValueLabel.tag = 1
        profitValueLabel.isUserInteractionEnabled = true
        let profitValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleProfitType))
        profitValueLabel.addGestureRecognizer(profitValueTapRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PortfolioManager.shared.delegate = self
        TickerDaemon.delegate = self
        updateUI()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destNavVC = segue.destination as? UINavigationController, let destVC = destNavVC.topViewController as? FilterController {
            destVC.delegate = self
            destVC.isSelector = true
            destVC.filter.transactionType = filter.transactionType
        }
    }

    // MARK: - Public Methods
    func updateUI() {
        portfolioDisplay = { portfolioDisplay }()
        showsRelativeProfit = { showsRelativeProfit }()
        
        if let investmentValue = PortfolioManager.shared.getProfitStats(for: filter.transactionType, timeframe: .allTime)?.startValue {
            investmentValueLabel.text = Format.getCurrencyFormatting(for: investmentValue, currency: PortfolioManager.shared.baseCurrency)
        } else {
            investmentValueLabel.text = "???"
        }
    }
    
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
    
    // MARK: - TickerDaemon Delegate
    func didUpdateCurrentPrice(for tradingPair: TradingPair) {
        updateUI()
    }
    
    // MARK: - Filter Delegate
    func didChangeSelectedAddresses() {
        updateUI()
    }
    
    func didChangeTransactionType(type: TransactionType) {
        filter.transactionType = type
    }

}
