//
//  AddresDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AddresDetailController: UITableViewController {

    // MARK: - Public Properties
    var address: Address!
    
    // MARK: - Private Properties
    let deleteIndexPath = IndexPath(row: 0, section: 2)
    
    // MARK: - Outlets
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var aliasField: UITextField!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        addressField.text = address.address
        aliasField.text = address.alias
        unitLabel.text = address.cryptoCurrency
        balanceLabel.text = String(address.balance)
    }
    
    // MARK: - Navigation
    @IBAction func setAlias(_ sender: UITextField) {
        guard let alias = sender.text, !alias.isEmpty else {
            return
        }
        
        do {
            try address.setAlias(alias)
        } catch {
            print(error)
        }
    }
    
    func deleteAddress() {
        do {
            try address!.portfolio!.removeAddress(address: address)
            self.navigationController?.popViewController(animated: true)
        } catch {
            // present error
            print(error)
        }
    }

    // MARK: - Table view Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == deleteIndexPath {
            deleteAddress()
        }
    }

}
