//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DashboardController: UIViewController, UITabBarControllerDelegate {
    
    // MARK: - Properties
    let wallet = Wallet()
    
    // Mark: - Outlets
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var portfolioGainLabel: UILabel!
    @IBOutlet weak var performanceTodayLabel: UILabel!
    @IBOutlet weak var currentPriceLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.delegate = self
    }
    
    // MARK: - Navigation
    @IBAction func unwindToDashboard(segue: UIStoryboardSegue) {
        if let sourceVC = segue.source as? AddAddressController, let addressString = sourceVC.address, let unit = sourceVC.unit {
            do {
                try wallet.addAddress(addressString, unit: unit)
            } catch {
                print(error)
            }
        }
    }
    
    // MARK: - TabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let destVC = viewController as? UINavigationController, let transactionVC = destVC.topViewController as? TransactionTableController {
            transactionVC.addresses = wallet.addresses
        }
    }
    
}
