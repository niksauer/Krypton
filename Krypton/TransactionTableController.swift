//
//  TransactionTableController.swift
//  Krypton
//
//  Created by Niklas Sauer on 22.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit
import CoreData

class TransactionTableController: FetchedResultsTableViewController, FilterDelegate {
    
    // MARK: - Public Properties
    var fetchedResultsController: NSFetchedResultsController<Transaction>?
    
    // MARK: - Private Properties
    private var database = AppDelegate.persistentContainer
    private var selectedTransaction: Transaction?
    
    private var addresses = [Address]() {
        didSet {
            updateUI()
        }
    }
    
    private var transactionFilter: TransactionType = .all {
        didSet {
            updateUI()
        }
    }

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updateAddresses), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addresses = PortfolioManager.shared.selectedAddresses
        updateUI()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? TransactionDetailController {
            destVC.transaction = selectedTransaction
        }
        
        if let destNavVC = segue.destination as? UINavigationController, let destVC = destNavVC.topViewController as? FilterController {
            destVC.delegate = self
            destVC.selectedTransactionType = transactionFilter
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
    
    @objc private func updateAddresses() {
        for (index, address) in addresses.enumerated() {
            if index == self.addresses.count-1 {
                address.update {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                address.update(completion: nil)
            }
        }
    }
    
    // MARK: - Filter Delegate
    func didChangeTransactionType(to type: TransactionType) {
        self.transactionFilter = type
    }
    
    func didChangeSelectedAddresses() {
        self.addresses = PortfolioManager.shared.selectedAddresses
    }
    
    // MARK: - TableView Data Source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "txCell", for: indexPath) as! TransactionCell
//        cell.configure(transaction: fetchedResultsController!.object(at: indexPath))
//        return cell
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        let transaction = fetchedResultsController!.object(at: indexPath)
        
        cell.textLabel?.text = Format.getCurrencyFormatting(for: transaction.amount, currency: transaction.owner!.blockchain)
        
        cell.detailTextLabel?.text = Format.getDateFormatting(for: transaction.date! as Date)
        if transaction.isOutbound {
            cell.textLabel?.textColor = UIColor.red
        } else {
            cell.textLabel?.textColor = UIColor.green
        }
    
        
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
