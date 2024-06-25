//
//  Bip21Invoice.swift
//  Pay Join
//
//  Created by Peter Denton on 3/19/24.
//

import Foundation


public struct Invoice: CustomStringConvertible, Hashable, Equatable {
    public var description: String {
        return ""
    }
    
    var address: String?
    var recipientsNpub: String?
    var amount: Double?
    
    init(_ urlString: String) {
        if let urlComponents = URLComponents(string: urlString), let queryItems = urlComponents.queryItems {
                address = urlComponents.path
            for item in queryItems {
                print("item: \(item)")
                switch item.name {
                case "pj":
                    recipientsNpub = item.value!.replacingOccurrences(of: "nostr:", with: "")
                case "amount":
                    amount = Double(item.value!)
                default:
                    break
                }
            }
        }
    }
}
