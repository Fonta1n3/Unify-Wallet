//
//  Utxo.swift
//  Pay Join
//
//  Created by Peter Denton on 2/13/24.
//

import Foundation

public struct Utxo: CustomStringConvertible, Hashable, Identifiable, Equatable {
    public let id: UUID = UUID()
    
    
    
    let amount: Double?
    let address: String?
    let desc: String?
    let solvable: Bool?
    let txid: String
    let vout: Int64
//    let walletId: UUID?
    let confs: Int64?
//    let safe: Bool?
//    let spendable: Bool?
    var isSelected: Bool
//    let reused: Bool?
//    //let capGain:String?
//    //let originValue:String?
//    let date: Date?
//    //let txUUID: UUID?
////    let amountFiat: String?
////    let amountSats: String?
//    let dict: [String:Any]
//    let frozen: Bool?
//    let path: String?
    //let value: Int?
//    let utxo: String?
    
    init(_ dictionary: [String: Any]) {
        //id = UUID()
        //id = dictionary["id"] as? UUID
        //label = dictionary["label"] as? String
        address = dictionary["address"] as? String
        amount = dictionary["amount"] as? Double
        desc = dictionary["desc"] as? String
        txid = dictionary["txid"] as? String ?? ""
        vout = dictionary["vout"] as? Int64 ?? 0
        //walletId = dictionary["walletId"] as? UUID
        confs = dictionary["confirmations"] as? Int64
        //spendable = dictionary["spendable"] as? Bool
        //safe = dictionary["safe"] as? Bool
        isSelected = dictionary["isSelected"] as? Bool ?? false
        //reused = dictionary["reused"] as? Bool
        //capGain = dictionary["capGain"] as? String
        //originValue = dictionary["originValue"] as? String
        //date = dictionary["date"] as? Date
        //txUUID = dictionary["txUUID"] as? UUID
        //frozen = dictionary["frozen"] as? Bool
        //path = dictionary["path"] as? String
        //value = dictionary["value"] as? Int
        solvable = dictionary["solvable"] as? Bool ?? false
//        utxo = dictionary["utxo"] as? String
//        dict = dictionary
    }
    
    public var description: String {
        return ""
    }
    
}
