//
//  Transaction.swift
//  Unify
//
//  Created by Peter Denton on 6/17/24.
//

import Foundation

/*
 {
    "address": "tb1quhahxct7rytahqd0rndwj4pylkw68nffa5mcwj",
    "category": "send",
    "amount": -0.00020000,
    "vout": 0,
    "fee": -0.00000413,
    "confirmations": 0,
    "trusted": true,
    "txid": "2919a4844e154e8017a28157b860b2c996de81c684563d3a5dc12178aea42c9f",
    "wtxid": "61d94b67697566861659d7bddb1405e6cb5f0c55db4659a675439e74287faf3e",
    "walletconflicts": [
    ],
    "time": 1718633220,
    "timereceived": 1718633220,
    "bip125-replaceable": "yes",
    "abandoned": false
  }
 */

public struct TransactionStruct: CustomStringConvertible, Hashable {
    let id = UUID()
    let amount: Double
    let fee: Double?
    let txid: String
    let timereceived: Int
    let confirmations: Int
    let category: String
    var date: String
    
    init(_ dictionary: [String: Any]) {
        amount = dictionary["amount"] as! Double
        fee = dictionary["fee"] as? Double
        txid = dictionary["txid"] as! String
        timereceived = dictionary["timereceived"] as! Int
        confirmations = dictionary["confirmations"] as! Int
        category = dictionary["category"] as! String
        
        let dateFormatter = DateFormatter()
        let dateDate = Date(timeIntervalSince1970: TimeInterval(timereceived))
        dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
        let dateString = dateFormatter.string(from: dateDate)
        date = dateString
    }
    
    public var description: String {
        return "An individual result from bitcoin-cli listtransactions."
    }
}
