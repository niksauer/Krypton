//
//  TransactionTableController.swift
//  Krypton
//
//  Created by Niklas Sauer on 22.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit
import CoreData

class TransactionTableController: FetchedResultsTableViewController {
    
    // MARK: - Properties
    var database = AppDelegate.persistentContainer
    var addresses = PortfolioManager.shared.selectedAddresses {
        didSet {
            updateUI()
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController<Transaction>?
    var selectedTransaction: Transaction?
    
    var transactionFilter: TransactionType = .all {
        didSet {
            updateUI()
        }
    }

    // MARK: - Initialization
    override func viewDidLoad() {
        updateUI()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? TransactionDetailController {
            destVC.transaction = selectedTransaction
        }
        
        if let destNavVC = segue.destination as? UINavigationController, let destVC = destNavVC.topViewController as? FilterController {
            destVC.transactionType = transactionFilter
        }
    }
    
    @IBAction func unwindFromFilterPanel(segue: UIStoryboardSegue) {
        if let sourceVC = segue.source as? FilterController, let selectedTransactionType = sourceVC.transactionType {
            transactionFilter = selectedTransactionType
            
            if sourceVC.selectionHasChanged {
                addresses = PortfolioManager.shared.selectedAddresses
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        let context = database.viewContext
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        switch transactionFilter {
        case .investment:
            request.predicate = NSPredicate(format: "owner IN %@ AND isInvestment = YES", addresses)
        case .other:
            request.predicate = NSPredicate(format: "owner IN %@ AND isInvestment = NO", addresses)
        case .all:
            request.predicate = NSPredicate(format: "owner IN %@", addresses)
        }
        
        fetchedResultsController = NSFetchedResultsController<Transaction>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController?.delegate = self
        try? fetchedResultsController?.performFetch()
        tableView.reloadData()
    }
    
    // MARK: - TableView Data Source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        
        let transaction = fetchedResultsController!.object(at: indexPath)
        cell.textLabel?.text = Currency.Crypto(rawValue: transaction.owner!.cryptoCurrency!)!.symbol + " " + Format.cryptoFormatter.string(from: NSNumber(value: transaction.amount))!
        cell.detailTextLabel?.text = Format.dateFormatter.string(from: transaction.date! as Date)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTransaction = fetchedResultsController!.object(at: indexPath)
        performSegue(withIdentifier: "showTransaction", sender: self)
    }
    
}

// MARK: - TableView Data Source
extension TransactionTableController {
   
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].name
        } else {
            return nil
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
}

// MARK: - NSFetchedResultsControllerDelegate
class FetchedResultsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections([sectionIndex], with: .fade)
        case .delete:
            tableView.deleteSections([sectionIndex], with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
