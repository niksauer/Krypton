//
//  AddAddressController.swift
//  Krypton
//
//  Created by Niklas Sauer on 19.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit
import CoreData

class AddAddressController: UIViewController {
    
    // MARK: - Properties
    var address: String?
    var unit: CryptoUnit?
    
    // MARK: - Outlets
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
     
    @IBAction func save(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToDashboard", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton, let addressString = addressField.text else {
            return
        }
        
        address = addressString
        unit = CryptoUnit.ETH
    }

}
