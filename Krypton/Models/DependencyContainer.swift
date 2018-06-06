//
//  DependencyContainer.swift
//  Krypton
//
//  Created by Niklas Sauer on 05.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

struct DependencyContainer {
    
    // Mark: - Singletons
    let kryptonDaemon: KryptonDaemon
    let portfolioManager: PortfolioManager
    let tickerDaemon: TickerDaemon = TickerDaemon.shared
    let blockchainDaemom: BlockchainDaemon
    
    // Mark: - Private Properties
    let viewContext: NSManagedObjectContext = CoreDataStack.shared.viewContext
    
    var blockchains: [Blockchain] {
        return Blockchain.allValues as! [Blockchain]
    }
    
    var currencyManager: CurrencyManager {
        return CurrencyManager()
    }
    
    var exchangeRateManager: ExchangeRateManager {
        return ExchangeRateManager(context: viewContext, tickerDaemon: tickerDaemon)
    }
    
    // Mark: - Initialization
    init() throws {
        do {
            portfolioManager = try PortfolioManager(context: viewContext, currencyManager: CurrencyManager())
        } catch {
            log.error("Failed to initialize PortfolioManager singleton: \(error)")
            throw error
        }
        
        blockchainDaemom = BlockchainDaemon()
        kryptonDaemon = KryptonDaemon(portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, blockchainDaemon: blockchainDaemom)
    }
    
}

extension DependencyContainer: ViewControllerFactory {
    
    // Main
    func makeAccountsViewController() -> AccountsViewController {
        return AccountsViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon)
    }
    
    func makeWatchlistViewController() -> WatchlistViewController {
        return WatchlistViewController(portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, currencyManager: currencyManager)
    }
    
    func makeDashboardViewController() -> DashboardViewController {
        return DashboardViewController(viewFactory: self, kryptonService: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon)
    }
    
    // Portfolio
    func makePortfoliosViewController() -> PortfoliosViewController {
        return PortfoliosViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, selectedPortfolio: nil, isSelector: false)
    }
    
    func makePortfolioSelectionViewController(selection: Portfolio?) -> PortfoliosViewController {
        return PortfoliosViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, selectedPortfolio: selection, isSelector: true)
    }
    
    func makeAddPortfolioViewController() -> AddPortfolioViewController {
        return AddPortfolioViewController(portfolioManager: portfolioManager)
    }
    
    func makePortfolioDetailViewController(for portfolio: Portfolio) -> PortfolioDetailViewController {
        return PortfolioDetailViewController(viewFactory: self, portfolio: portfolio, portfolioManager: portfolioManager)
    }
    
    // Address
    func makeAddressDetailViewController(for address: Address) -> AddressDetailViewController {
        return AddressDetailViewController(viewFactory: self, address: address)
    }
    
    func makeAddAdressViewController() -> AddAddressViewController {
        return AddAddressViewController(viewFactory: self, portfolioManager: portfolioManager, blockchains: blockchains)
    }
    
    func makeAmountByAddressViewController(for transaction: Transaction) -> AmountByAddressViewController {
        return AmountByAddressViewController(transaction: transaction, portfolioManager: portfolioManager)
    }
    
    // Transaction
    func makeTransactionsViewController(for addresses: [Address]) -> TransactionsViewController {
        return TransactionsViewController(viewFactory: self, addresses: addresses, portfolioManager: portfolioManager, searchContext: viewContext)
    }
    
    func makeTransactionDetailViewController(for transaction: Transaction) -> TransactionDetailViewController {
        return TransactionDetailViewController(viewFactory: self, transaction: transaction, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, blockchainDaemon: blockchainDaemom)
    }
    
    // Settings
    func makeSettingsViewController() -> SettingsViewController {
        return SettingsViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager)
    }
    
    // Shared
    func makeCurrencySelector(type: CurrencyType, selection: Currency?) -> CurrencySelectorViewController {
        return CurrencySelectorViewController(type: type, selection: selection, currencyManager: currencyManager)
    }
    
    func makeFilterViewController() -> FilterViewController {
        return FilterViewController(portfolioManager: portfolioManager)
    }
    
}
