//
//  EthplorerService.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import NetworkKit

struct EthplorerService: JSONService {
    
    // MARK: - Public Types
    struct TokenTransfer {
        var identifier: String
        var from: String
        var to: String
        var amount: Double
    }
    
    // MARK: - Service
    let client: JSONAPIClient
    
    init(hostURL: String, port: Int?, credentials: APICredentialStore?) {
        self.client = JSONAPIClient(hostURL: hostURL, port: port, basePath: nil, credentials: credentials)
    }
    
    // MARK: - Private Properties
//    private let baseURL = "https://api.ethplorer.io/"
    private let apiKey = "freekey"
    
    // MARK: - Public Methods
    func getInfo(address: Ethereum) {
        client.makeGETRequest(to: "getAddressInfo", params: [
            "apiKey": apiKey,
            "address": address.identifier!
        ]) { result in
            
        }
    }
    
    func getInfo(contractAddress: String) {
        client.makeGETRequest(to: "getTokenInfo", params: [
            "apiKey": apiKey,
            "address": contractAddress
        ]) { result in
            
        }
    }
    
    func getTokenBalance(for address: Ethereum, contractAddress: String) {
        client.makeGETRequest(to: "getAddressHistory", params: [
            "apiKey": apiKey,
            "address": address.identifier!,
            "token": contractAddress,
            "type": "transfer",
            "limit:": "10"
        ]) { result in
            
        }
    }
   
}
