//
//  DescriptorInfo.swift
//  UnifyWallet
//
//  Created by Peter Denton on 7/1/24.
//

import Foundation


public struct DescriptorInfo: CustomStringConvertible {
    
    /*
     {                                   (json object)
       "descriptor" : "str",             (string) The descriptor in canonical form, without private keys
       "checksum" : "str",               (string) The checksum for the input descriptor
       "isrange" : true|false,           (boolean) Whether the descriptor is ranged
       "issolvable" : true|false,        (boolean) Whether the descriptor is solvable
       "hasprivatekeys" : true|false     (boolean) Whether the input descriptor contained at least one private key
     }
     */
    
    let checksum: String
    let hasprivatekeys: Bool
    let issolvable: Bool
    let isrange: Bool
    let descriptor: String
    //let desc_with_h_checksum: String
    
    init(_ dictionary: [String: Any]) {
        hasprivatekeys = dictionary["hasprivatekeys"] as! Bool
        checksum = dictionary["checksum"] as! String
        descriptor = dictionary["descriptor"] as! String
        issolvable = dictionary["issolvable"] as! Bool
        isrange = dictionary["isrange"] as! Bool
    }
    
    public var description: String {
        return ""
    }
}
