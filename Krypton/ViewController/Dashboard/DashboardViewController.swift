//
//  DashboardViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import Charts

enum AnalysisType: String {
    case exchangeValue = "Exchange Value"
    case relativeProfit = "Relative Profit"
    case absoluteProfit = "Absolute Profit"
}

class DashboardViewController: UIViewController, KryptonDaemonDelegate, TickerDaemonDelegate, FilterDelegate, ChartViewDelegate {

    // Mark: - Typealiases
    typealias ColorPalette = DashboardColorPalette
    
    // Mark: - Outlets
    @IBOutlet weak var comparisonDateSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var analysisTypeLabel: UILabel!
    @IBOutlet weak var previousAnalysisTypeButton: UIButton!
    @IBOutlet weak var nextAnalysisTypeButton: UIButton!
    
    @IBOutlet weak var upperAnalysisChartSeparator: UIView!
    @IBOutlet weak var analysisChartViewContainer: UIView!
    @IBOutlet weak var lowerAnalysisChartSeparator: UIView!
    
    @IBOutlet weak var insightsViewContainer: UIView!
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let colorPalette: ColorPalette
    
    private let analysisChartViewController: AnalysisChartViewController
    private let insightsViewController: InsightsViewController
    
    private var timeframe: ChartTimeframe = .week {
        didSet {
            if let comparisonDate = timeframe.comparisonDate {
                self.comparisonDate = comparisonDate
            } else if let oldestTransaction = portfolioManager.getOldestTransaction() {
                self.comparisonDate = oldestTransaction.date!
            } else {
                self.comparisonDate = nil
            }
            
            analysisChartViewController.setXAxisLabelCount(timeframe.labelCount)
            analysisChartViewController.dateFormatter = timeframe.dateFormatter
            analysisChartViewController.comparisonDate = comparisonDate
            
            insightsViewController.comparisonDate = comparisonDate
        
            updateUI()
        }
    }
    
    private var comparisonDate: Date?
    
    private var filter: Filter = Filter() {
        didSet {
            analysisChartViewController.transactionType = filter.transactionType
            insightsViewController.transactionType = filter.transactionType
            
            updateUI()
        }
    }
    
    private var analysisType: AnalysisType = .exchangeValue {
        didSet {
            analysisChartViewController.type = analysisType
            insightsViewController.analysisType = analysisType
            
            updateUI()
        }
    }
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, kryptonDaemon: KryptonDaemon, portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, colorPalette: ColorPalette) {
        self.viewFactory = viewFactory
        self.kryptonDaemon = kryptonDaemon
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        self.colorPalette = colorPalette
        
        self.analysisChartViewController = viewFactory.makeAnalysisChartViewController(analysisType: analysisType, transactionType: filter.transactionType)
        self.insightsViewController = viewFactory.makeInsightsViewController(analysisType: analysisType, transactionType: filter.transactionType)
        
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
        
        // setup colors
        view.backgroundColor = colorPalette.backgroundColor
        analysisTypeLabel.textColor = colorPalette.primaryTextColor
        comparisonDateSegmentedControl.tintColor = colorPalette.tintColor
        previousAnalysisTypeButton.tintColor = colorPalette.tintColor
        nextAnalysisTypeButton.tintColor = colorPalette.tintColor
        upperAnalysisChartSeparator.backgroundColor = colorPalette.separatorColor
        lowerAnalysisChartSeparator.backgroundColor = colorPalette.separatorColor
        
        // setup analysis charts VC
        addChildViewController(analysisChartViewController)
        analysisChartViewContainer.addSubview(analysisChartViewController.view)
        analysisChartViewController.didMove(toParentViewController: self)
        analysisChartViewController.view.translatesAutoresizingMaskIntoConstraints = false
        analysisChartViewController.view.pin(to: analysisChartViewContainer)
        
        // setup insights VC
        addChildViewController(insightsViewController)
        insightsViewContainer.addSubview(insightsViewController.view)
        insightsViewController.didMove(toParentViewController: self)
        insightsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        insightsViewController.view.pin(to: insightsViewContainer)
        
        // chart timeframe
        timeframe = .week
        
        // setup segmented control
        comparisonDateSegmentedControl.selectedSegmentIndex = timeframe.rawValue
        
        // final view refresh
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        kryptonDaemon.delegate = self
        tickerDaemon.delegate = self
        
        navigationController?.navigationBar.barStyle = .blackTranslucent
        navigationController?.navigationBar.tintColor = colorPalette.tintColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        kryptonDaemon.delegate = nil
        tickerDaemon.delegate = nil
    }

    // MARK: - Private Methods
    private func updateUI() {
        analysisTypeLabel.text = analysisType.rawValue
        
        analysisChartViewController.updateChartData()
        insightsViewController.updateUI()
    }
    
    @objc private func filterButtonPressed() {
        let filterViewController = viewFactory.makeFilterViewController(showsAdvancedProperties: false, isAddressSelector: true)
        filterViewController.delegate = self
        filterViewController.filter = filter
        let filterNavigationController = UINavigationController(rootViewController: filterViewController)
        navigationController?.present(filterNavigationController, animated: true)
    }
    
    @IBAction func previousAnalysisTypeButtonPressed(_ sender: UIButton) {
        switch analysisType {
        case .exchangeValue:
            analysisType = .absoluteProfit
        case .relativeProfit:
            analysisType = .exchangeValue
        case .absoluteProfit:
            analysisType = .relativeProfit
        }
    }
    
    @IBAction func nextAnalysisTypeButtonPressed(_ sender: UIButton) {
        switch analysisType {
        case .exchangeValue:
            analysisType = .relativeProfit
        case .relativeProfit:
            analysisType = .absoluteProfit
        case .absoluteProfit:
            analysisType = .exchangeValue
        }
    }
    
    @IBAction private func didChangeChartTimeframe(_ sender: UISegmentedControl) {
        timeframe = ChartTimeframe(rawValue: sender.selectedSegmentIndex)!
    }
    
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
