//
//  TransactionController.swift
//  Krypton
//
//  Created by Niklas Sauer on 22.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit
import CoreData

class TransactionController: UIViewController {

    // MARK: - Properties
    var addresses: [Address]?
    var transaction: Transaction?
    
    // MARK: - Outlets
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var senderField: UITextField!
    @IBOutlet weak var receiverField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var typeField: UITextField!
    @IBOutlet weak var exchangeValueField: UITextField!
    @IBOutlet weak var blockField: UITextField!
    @IBOutlet weak var hashField: UITextField!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = editButtonItem
        
        if let tx = transaction {
            let cryptoCurrency = Currency.Crypto(rawValue: tx.owner!.cryptoCurrency!)!
            let unitSymbol = Currency.getSymbol(for: cryptoCurrency)!
            valueLabel.text = unitSymbol + " " + Format.cryptoFormatter.string(from: NSNumber(value: tx.value))!
            
            let senderName = addresses?.first(where: { $0.address == tx.from!})?.alias
            senderField.text = senderName ?? tx.from
            
            let receiverName = addresses?.first(where: { $0.address == tx.to!})?.alias
            receiverField.text = receiverName ?? tx.to
            
            dateField.text = Format.dateFormatter.string(from: tx.date! as Date)
            typeField.text = tx.type
            blockField.text = String(tx.block)
            hashField.text = tx.identifier
            
            if let transactionValue = TickerPrice.getTransactionValue(for: tx) {
                exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: transactionValue))!
            } else {
                exchangeValueField.text = "???"
            }
        }

    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
        exchangeValueField.isEnabled = !exchangeValueField.isEnabled
        
        if !editing {
            if let newValue = Double(exchangeValueField.text!) {
                transaction?.updateUserExchangeValue(newValue, in: AppDelegate.viewContext)
            }
        }
    }
}
