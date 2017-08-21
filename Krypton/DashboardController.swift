//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DashboardController: UIViewController {
    
    // MARK: - Properties
    var wallet = Wallet()
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
}
