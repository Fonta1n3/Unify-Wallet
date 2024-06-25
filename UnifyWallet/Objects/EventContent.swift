//
//  EventContent.swift
//  Unify
//
//  Created by Peter Denton on 6/8/24.
//

import Foundation

public struct EventContent: CustomStringConvertible {
    let psbt: String?
    let parameters: EventContentParams?
    
    init(_ dictionary: [String: Any]) {
        psbt = dictionary["psbt"] as? String
        parameters = dictionary["parameters"] as? EventContentParams
    }
    
    public var description: String {
        return "Unencrypted event content."
    }
}


// These parameters are optional and for now ignored.
public struct EventContentParams: CustomStringConvertible {
    let version: Int?
    let maxAdditionalFeeContribution: Int?
    let additionalFeeOutputIndex: Int?
    let minFeeRate: Int?
    let disableOutputSubstitution: Bool?
    
    init(dictionary: [String: Any]) {
        version = dictionary["version"] as? Int
        maxAdditionalFeeContribution = dictionary["maxAdditionalFeeContribution"] as? Int
        additionalFeeOutputIndex = dictionary["additionalFeeOutputIndex"] as? Int
        minFeeRate = dictionary["minFeeRate"] as? Int
        disableOutputSubstitution = dictionary["disableOutputSubstitution"] as? Bool
    }
    
    public var description: String {
        return ""
    }
}
