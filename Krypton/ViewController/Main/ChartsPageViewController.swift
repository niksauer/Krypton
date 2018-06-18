//
//  ChartsPageViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import UIKit

class ChartsPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    // Mark: - Private Properties
    private var pages: [UIViewController]
    private var pendingIndex: Int?
    
    // Mark: - Public Properties
    var currentIndex: Int?
    
    // Mark: - Initialization
    init(portfolioManager: PortfolioManager, taxAdviser: TaxAdviser, transactionType: TransactionType) {
        let absoluteProfitHistoryViewController = AbsoluteProfitHistoryViewController(portfolioManager: portfolioManager, taxAdviser: taxAdviser, transactionType: transactionType)
        let absoluteProfitHistoryViewController2 = AbsoluteProfitHistoryViewController(portfolioManager: portfolioManager, taxAdviser: taxAdviser, transactionType: transactionType)
        
        pages = [absoluteProfitHistoryViewController, absoluteProfitHistoryViewController2]
        
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Mark: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
    
        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: false, completion: nil)
        }
        
        // page control
        let pageControlAppearance = UIPageControl.appearance(whenContainedInInstancesOf: [ChartsPageViewController.self])
        pageControlAppearance.pageIndicatorTintColor = UIColor.gray
        pageControlAppearance.currentPageIndicatorTintColor = UIColor.black
    }
    
    // Mark: - Public Method
    func setXAxisLabelCount(_ count: Int) {
        for viewController in pages {
            (viewController as! AbsoluteProfitHistoryViewController).setXAxisLabelCount(count)
        }
    }
    
    func setDateFormatter(_ dateFormatter: DateFormatter) {
        for viewController in pages {
            guard var viewController = viewController as? AnalysisChartViewController else {
                continue
            }
            
            viewController.dateFormatter = dateFormatter
        }
    }
    
    func setComparisonDate(_ date: Date?) {
        for viewController in pages {
            guard var viewController = viewController as? AnalysisChartViewController else {
                continue
            }
            
            viewController.comparisonDate = date
        }
    }
    
    // Mark: - UIPageViewController DataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = pages.index(of: viewController)!
        let previousIndex = abs((index - 1) % pages.count)
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = pages.index(of: viewController)!
        let nextIndex = abs((index + 1) % pages.count)
        return pages[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // Mark: - UIPageViewController Delegate
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingIndex = pages.index(of: pendingViewControllers.first!)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        
        currentIndex = pendingIndex
    }
    
}
