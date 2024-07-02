//
//  NetworkInfo.swift
//  UnifyWallet
//
//  Created by Peter Denton on 7/1/24.
//

import Foundation

public struct NetworkInfo: CustomStringConvertible {
    
    let version: Int
    //let torReachable:Bool
    
    init(dictionary: [String: Any]) {
        self.version = dictionary["version"] as! Int
        //self.torReachable = dictionary["reachable"] as? Bool ?? false
    }
    
    public var description: String {
        return ""
    }
}
