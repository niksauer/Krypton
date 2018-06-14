//
//  ViewControllerFactory.swift
//  Krypton
//
//  Created by Niklas Sauer on 06.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

protocol ViewControllerFactory {
    
    // Main
    func makeAccountsViewController() -> AccountsViewController
    func makeWatchlistViewController() -> WatchlistViewController
    func makeDashboardViewController() -> DashboardViewController
    
    // Portfolio
    func makePortfoliosViewController() -> PortfoliosViewController
    func makePortfolioSelectorViewController(selection: Portfolio?) -> PortfoliosViewController
    func makeAddPortfolioViewController() -> AddPortfolioViewController
    func makePortfolioDetailViewController(for portfolio: Portfolio) -> PortfolioDetailViewController
    
    // Address
    func makeAddressDetailViewController(for address: Address) -> AddressDetailViewController
    func makeAddAdressViewController() -> AddAddressViewController
    
    // Transaction
    func makeTransactionsViewController(for addresses: [Address]) -> TransactionsViewController
    func makeTransactionDetailViewController(for transaction: Transaction) -> TransactionDetailViewController
    func makeAmountByAddressViewController(for transaction: BitcoinTransaction, type: AmountByAddressType) -> AmountByAddressViewController
    
    // Settings
    func makeSettingsViewController() -> SettingsViewController
    func makeLogDataViewController() -> LogDataViewController?
    
    // Shared
    func makeCurrencySelector(type: CurrencyType, selection: Currency?) -> CurrencySelectorViewController
    func makeFilterViewController(showsAdvancedProperties: Bool, isAddressSelector: Bool) -> FilterViewController
    
}
