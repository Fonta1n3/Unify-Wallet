//
//  SignerStruct.swift
//  Pay Join
//
//  Created by Peter Denton on 4/24/24.
//

import Foundation


public struct SignerStruct: CustomStringConvertible {
    let encryptedData:Data?
    let passphrase:Data?
    
    init(dictionary: [String: Any]) {
        encryptedData = dictionary["encryptedData"] as? Data
        passphrase = dictionary["passphrase"] as? Data
    }
    
    public var description: String {
        return ""
    }
}
