//
//  EthplorerAPI.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum EthplorerError: Error {
    case invalidJSONData
}

struct EthplorerAPI {
    
    // MARK: - Private Properties
    private static let baseURL = "https://api.ethplorer.io/"
    private static let apiKey = "freekey"
    
    private enum Method: String {
        case getTokenInfo
        case getAddressInfo
        case getAddressHistory
    }
    
    // MARK: - Public Properties
    struct TokenTransfer {
        var identifier: String
        var from: String
        var to: String
        var amount: Double
    }
    
    // MARK: - Private Methods
    private static func ethplorerURL(method: Method, parameters: [String: String]) -> URL {
        var components = URLComponents(string:  baseURL.appending("/\(method.rawValue)"))!
        var queryItems = [URLQueryItem]()
        
        let baseParams = [
            "apikey" : apiKey
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        for (key, value) in parameters {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        components.queryItems = queryItems
        return components.url!
    }
  
    // MARK: - Public Methods
    // MARK: URL Builder
    static func tokenInfoURL(for contractAddress: String) -> URL {
        return ethplorerURL(method: .getTokenInfo, parameters: [
            "address": contractAddress,
        ])
    }
    
    static func addressInfoURL(for address: String) -> URL {
        return ethplorerURL(method: .getAddressInfo, parameters: [
            "address": address,
        ])
    }
    
    static func tokenBalanceURL(for address: String, contractAddress: String) -> URL {
        return ethplorerURL(method: .getAddressHistory, parameters: [
            "address": address,
            "token": contractAddress,
            "type": "transfer",
            "limit:": "10"
        ])
    }
    
}
