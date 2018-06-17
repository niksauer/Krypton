//
//  AnalysisChartsViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import Charts

class AnalysisChartsViewController: UIViewController, ChartViewDelegate {

    // Mark: - Views
    private let lineChartView: LineChartView
    
    // Mark: - Private Properties
    private let portfolioManager: PortfolioManager
    private let taxAdviser: TaxAdviser
    
    private var referenceTimestamp: Double!

    // Mark: - Public Properties
    var transactionType: TransactionType
    
    var comparisonDate: Date? {
        didSet {
            updateChartData()
        }
    }
    
    var dateFormatter: DateFormatter!
    
    // Mark: - Initialization
    init(portfolioManager: PortfolioManager, taxAdviser: TaxAdviser, transactionType: TransactionType) {
        self.portfolioManager = portfolioManager
        self.taxAdviser = taxAdviser
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
        lineChartView.minOffset = 0
        lineChartView.extraRightOffset = 4
        
        lineChartView.leftAxis.enabled = false
        
        lineChartView.rightAxis.enabled = true
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.rightAxis.gridLineWidth = 0.3
        lineChartView.rightAxis.labelPosition = .outsideChart
        lineChartView.rightAxis.labelCount = 4
        lineChartView.rightAxis.xOffset = 5
        lineChartView.rightAxis.valueFormatter = LargeValueFormatter()
        
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true
        lineChartView.xAxis.gridLineDashLengths = [2, 2]
        lineChartView.xAxis.valueFormatter = self
    }
    
    // Mark: - Private Methods
    private func updateChartData() {
        guard let comparisonDate = comparisonDate else {
            lineChartView.data = nil
            return
        }
        
        guard let rawData = taxAdviser.getAbsoluteProfitHistory(for: portfolioManager.selectedAddresses, since: comparisonDate, type: transactionType) else {
            lineChartView.data = nil
            return
        }
        
        guard rawData.count >= 1 else {
            lineChartView.data = nil
            return
        }
        
        referenceTimestamp = rawData.first!.date.timeIntervalSince1970
        
        var entries = [ChartDataEntry]()
        entries = rawData.map { return ChartDataEntry(x: $0.date.timeIntervalSince1970 - referenceTimestamp, y: $0.profit) }
        
        let dataset = LineChartDataSet(values: entries, label: nil)
        dataset.lineWidth = 2.5
        dataset.circleRadius = 3
        dataset.drawValuesEnabled = false
        dataset.drawFilledEnabled = true
        dataset.drawHorizontalHighlightIndicatorEnabled = false
        dataset.drawCirclesEnabled = false
        
        let data = LineChartData(dataSet: dataset)
        lineChartView.data = data
    }
    
    // Mark: - Public Methods
    func setXAxisLabelCount(_ count: Int) {
        lineChartView.xAxis.setLabelCount(count, force: true)
    }
}

extension AnalysisChartsViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value + referenceTimestamp))
    }
}
