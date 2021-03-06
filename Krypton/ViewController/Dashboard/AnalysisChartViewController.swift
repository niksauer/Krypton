//
//  AnalysisChartViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import Charts

class AnalysisChartViewController: UIViewController, ChartViewDelegate {

    // Mark: - Typealiases
    typealias ColorPalette = DashboardColorPalette
    
    // Mark: - Views
    private let lineChartView: LineChartView
    
    // Mark: - Private Properties
    private let portfolioManager: PortfolioManager
    private let taxAdviser: TaxAdviser
    private let colorPalette: ColorPalette
    
    private var referenceTimestamp: Double!

    // Mark: - Public Properties
    var type: AnalysisType
    var transactionType: TransactionType
    var comparisonDate: Date?
    var dateFormatter: DateFormatter!
    
    // Mark: - Initialization
    init(portfolioManager: PortfolioManager, taxAdviser: TaxAdviser, anaylsisType: AnalysisType, transactionType: TransactionType, colorPalette: ColorPalette) {
        self.portfolioManager = portfolioManager
        self.taxAdviser = taxAdviser
        self.colorPalette = colorPalette
        self.type = anaylsisType
        self.transactionType = transactionType
        
        lineChartView = LineChartView()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Mark: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(lineChartView)
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.pin(to: view)
        
        lineChartView.delegate = self
        lineChartView.dragEnabled = true
        lineChartView.setScaleEnabled(false)
        lineChartView.chartDescription?.enabled = false
        lineChartView.legend.enabled = false
        lineChartView.noDataText = "No data available."
        lineChartView.noDataTextColor = colorPalette.secondaryTextColor
        lineChartView.minOffset = 0
        lineChartView.extraTopOffset = 4
        lineChartView.extraLeftOffset = 4
        lineChartView.extraRightOffset = 4
        lineChartView.extraBottomOffset = 8
        
        lineChartView.leftAxis.enabled = false
        
        lineChartView.rightAxis.enabled = true
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.rightAxis.gridLineWidth = 0.3
        lineChartView.rightAxis.labelPosition = .insideChart
        lineChartView.rightAxis.drawTopYLabelEntryEnabled = true
        lineChartView.rightAxis.labelCount = 4
        lineChartView.rightAxis.xOffset = 4
        lineChartView.rightAxis.yOffset = -4
        lineChartView.rightAxis.valueFormatter = LargeValueFormatter()
        
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true
        lineChartView.xAxis.gridLineDashLengths = [2, 2]
        lineChartView.xAxis.valueFormatter = self
        
        // color setup
        lineChartView.backgroundColor = colorPalette.chartBackgroundColor
        lineChartView.xAxis.labelTextColor = colorPalette.secondaryTextColor
        lineChartView.rightAxis.labelTextColor = colorPalette.secondaryTextColor
        lineChartView.rightAxis.gridColor = colorPalette.chartGridColor
        lineChartView.xAxis.gridColor = colorPalette.chartGridColor
        
        updateUI()
    }
    
    // Mark: - Private Methods
    func updateChartData() {
        guard let comparisonDate = comparisonDate else {
            lineChartView.data = nil
            return
        }
        
        var rawData: [(Date, Double)]?
        
        switch type {
        case .exchangeValue:
            rawData = taxAdviser.getExchangeValueHistory(for: portfolioManager.selectedAddresses, since: comparisonDate, type: transactionType)
        case .absoluteProfit:
//            rawData = taxAdviser.getAbsoluteProfitHistory(for: portfolioManager.selectedAddresses, since: comparisonDate, type: transactionType)?.history
            break
        case .relativeProfit:
//            rawData = taxAdviser.getRelativeProfitHistory(for: portfolioManager.selectedAddresses, since: comparisonDate, type: transactionType)?.history
            break
        }
        
        guard let data = rawData, data.count >= 1 else {
            lineChartView.data = nil
            return
        }
        
        referenceTimestamp = data.first!.0.timeIntervalSince1970
        
        var entries = [ChartDataEntry]()
        entries = data.map { return ChartDataEntry(x: $0.0.timeIntervalSince1970 - referenceTimestamp, y: $0.1) }
        
        let dataset = LineChartDataSet(values: entries, label: nil)
        dataset.lineWidth = 2.5
        dataset.circleRadius = 3
        dataset.drawValuesEnabled = false
        dataset.drawFilledEnabled = true
        dataset.drawHorizontalHighlightIndicatorEnabled = false
        dataset.drawCirclesEnabled = false
        
        // colors
        dataset.fillColor = colorPalette.chartFillColor
        dataset.colors = [colorPalette.chartLineColor]
        
        // set chart data
        let chartData = LineChartData(dataSet: dataset)
        lineChartView.data = chartData
    }
    
    // Mark: - Public Methods
    func updateUI() {
        updateChartData()
    }
    
    func setXAxisLabelCount(_ count: Int) {
        lineChartView.xAxis.setLabelCount(count, force: true)
    }
    
}

extension AnalysisChartViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value + referenceTimestamp))
    }
}
