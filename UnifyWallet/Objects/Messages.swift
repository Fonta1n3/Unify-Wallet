//
//  Messages.swift
//  Pay Join
//
//  Created by Peter Denton on 3/4/24.
//

import Foundation

enum Messages : String {
    case contentViewPrompt
    case savedCredentials
    
    public var description: String {
        switch self {
            case .contentViewPrompt:
                return "Select Config to export authentication credentials for your bitcoin.conf and to select a wallet."
            
        case .savedCredentials:
            return "Unify created default credentials to connect to your node. Go to Config to view, edit or export them."
        }
    }
}
