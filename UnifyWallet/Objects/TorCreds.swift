//
//  AuthKeys.swift
//  UnifyWallet
//
//  Created by Peter Denton on 7/7/24.
//

import Foundation

public struct TorCreds: CustomStringConvertible {
    
    let encryptedPrivateKey: Data
    let publicKey: String
    
    init(dictionary: [String:Any]) {
        encryptedPrivateKey = dictionary["encryptedPrivateKey"] as! Data
        publicKey = dictionary["publicKey"] as! String
    }
    
    public var description = ""
}
