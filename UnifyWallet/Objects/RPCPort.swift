//
//  RPCPort.swift
//  Pay Join
//
//  Created by Peter Denton on 2/13/24.
//

import Foundation

public struct RPCPort: CustomStringConvertible {
    public var description: String {
        return ""
    }
    
    let port: Int
    
    init(_ int: Int) {
        port = int
    }
}
