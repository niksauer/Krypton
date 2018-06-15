//
//  DashboardViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import Charts

class DashboardViewController: UIViewController, KryptonDaemonDelegate, TickerDaemonDelegate, FilterDelegate, ChartViewDelegate {

    // Mark: - Outlets
    @IBOutlet weak var lineChartView: LineChartView!
    
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var portfolioLabel: UILabel!
    @IBOutlet weak var profitValueLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    @IBOutlet weak var investmentValueLabel: UILabel!
    @IBOutlet weak var investmentLabel: UILabel!
    
    // MARK: - Private Types
    private enum PortfolioDisplayType {
        case currentExchangeValue
        case relativeProfit
        case absoluteProfit
    }
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let currencyFormatter: CurrencyFormatter
    private let taxAdviser: TaxAdviser
    private let comparisonDateFormatter: DateFormatter

    private var comparisonDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())! {
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
            guard let currentExchangeValue = taxAdviser.getExchangeValue(for: portfolioManager.selectedAddresses, on: Date(), type: filter.transactionType), let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: filter.transactionType) else {
                portfolioValueLabel.text = "???"
                return
            }
            
            switch portfolioDisplay {
            case .currentExchangeValue:
                portfolioLabel.text = "Total Portfolio Value"
                portfolioValueLabel.text = currencyFormatter.getFormatting(for: currentExchangeValue, currency: portfolioManager.quoteCurrency)
            case .relativeProfit:
                portfolioLabel.text = "Total Relative Profit"
                portfolioValueLabel.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats)
            case .absoluteProfit:
                portfolioLabel.text = "Total Absolute Profit"
                portfolioValueLabel.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
            }
        }
    }
    
    private var showsRelativeProfit: Bool = true {
        didSet {
            guard let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .sinceDate(comparisonDate), type: filter.transactionType) else {
                profitValueLabel.text = "???"
                return
            }

            profitLabel.text = "Since \(comparisonDateFormatter.string(from: comparisonDate))"
            
            if showsRelativeProfit {
                profitValueLabel.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats)
            } else {
                profitValueLabel.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
            }
        }
    }
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, kryptonDaemon: KryptonDaemon, portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, currencyFormatter: CurrencyFormatter, taxAdviser: TaxAdviser, comparisonDateFormatter: DateFormatter) {
        self.viewFactory = viewFactory
        self.kryptonDaemon = kryptonDaemon
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        self.currencyFormatter = currencyFormatter
        self.taxAdviser = taxAdviser
        self.comparisonDateFormatter = comparisonDateFormatter
        
        super.init(nibName: nil, bundle: nil)
        
        title = "Dashboard"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterButtonPressed))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // portfolio
        portfolioValueLabel.isUserInteractionEnabled = true
        let portfolioValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePortfolioDisplayType))
        portfolioValueLabel.addGestureRecognizer(portfolioValueTapRecognizer)
        
        // profit
        profitValueLabel.isUserInteractionEnabled = true
        let profitValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleProfitType))
        profitValueLabel.addGestureRecognizer(profitValueTapRecognizer)
        
        // investment
        investmentLabel.text = "Total Investment"
        
        // setup chart view
        lineChartView.delegate = self
        lineChartView.dragEnabled = true
        lineChartView.setScaleEnabled(false)
        lineChartView.chartDescription?.enabled = false
        lineChartView.legend.enabled = false
        lineChartView.rightAxis.enabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        kryptonDaemon.delegate = self
        tickerDaemon.delegate = self
        
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        kryptonDaemon.delegate = nil
        tickerDaemon.delegate = nil
    }

    // MARK: - Private Methods
    @objc private func filterButtonPressed() {
        let filterViewController = viewFactory.makeFilterViewController(showsAdvancedProperties: false, isAddressSelector: true)
        filterViewController.delegate = self
        filterViewController.filter = filter
        let filterNavigationController = UINavigationController(rootViewController: filterViewController)
        navigationController?.present(filterNavigationController, animated: true)
    }
    
    private func updateUI() {
        portfolioDisplay = { portfolioDisplay }()
        showsRelativeProfit = { showsRelativeProfit }()
        
        if let investmentValue = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: filter.transactionType)?.startValue {
            investmentValueLabel.text = currencyFormatter.getFormatting(for: investmentValue, currency: portfolioManager.quoteCurrency)
        } else {
            investmentValueLabel.text = "???"
        }
        
        updateChartData()
    }
    
    @objc private func toggleProfitType(sender: UITapGestureRecognizer) {
        showsRelativeProfit = !showsRelativeProfit
    }
    
    @objc private func togglePortfolioDisplayType(sender: UITapGestureRecognizer) {
        switch portfolioDisplay {
        case .currentExchangeValue:
            portfolioDisplay = .relativeProfit
        case .relativeProfit:
            portfolioDisplay = .absoluteProfit
        case .absoluteProfit:
            portfolioDisplay = .currentExchangeValue
        }
    }
    
    func updateChartData() {
        guard let rawData = taxAdviser.getAbsoluteProfitHistory(for: portfolioManager.selectedAddresses, since: comparisonDate, type: filter.transactionType) else {
            lineChartView.data = nil
            return
        }
        
        let entries = rawData.map { return ChartDataEntry(x: $0.date.timeIntervalSince1970, y: $0.profit)}
        let dataset = LineChartDataSet(values: entries, label: nil)
        
        let data = LineChartData(dataSet: dataset)
        lineChartView.data = data
    }
    
    // MARK: - ChartView Delegate
    
    
    // MARK: - KryptonDaemon Delegate
    func kryptonDaemonDidUpdate(_ kryptonDaemon: KryptonDaemon) {
        updateUI()
    }
    
    // MARK: - TickerDaemon Delegate
    func tickerDaemon(_ tickerDaemon: TickerDaemon, didUpdateCurrentExchangeRateForCurrencyPair currencyPair: CurrencyPair) {
        updateUI()
    }
    
    // MARK: - FilterController Delegate
    func filterControllerDidSetSelectedAddresses(_ filterController: FilterViewController) {
        updateUI()
    }
 
    func filterController(_ filterController: FilterViewController, didSetTransactionType type: TransactionType) {
        filter.transactionType = type
    }
    
}
