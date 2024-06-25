//
//  Errors.swift
//  Pay Join
//
//  Created by Peter Denton on 3/4/24.
//

import Foundation

enum CoreDataError : Error, LocalizedError {
    case notSaved
    case notPresent
    
    public var errorDescription: String? {
        switch self {
            case .notSaved:
                return "Unable to save your credentials."
        case .notPresent:
            return "No credentials were found."
        }
    }
}

enum BitcoinCoreError: Error, LocalizedError {
    case noWallets
    
    public var errorDescription: String? {
        switch self {
        case .noWallets:
            return "No response from bitcoin-cli listwallets. In order to gain full functionality you need to connect your node and select a wallet."
        }
    }
}

