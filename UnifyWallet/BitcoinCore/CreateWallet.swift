//
//  CreateWallet.swift
//  UnifyWallet
//
//  Created by Peter Denton on 7/1/24.
//

import Foundation

class CreateWallet {
    
    static var index = 0
    static var processedWatching = [String]()
    static var version: Int = 0
            
    class func accountMap(_ accountMap: [String:Any], completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        let password = accountMap["password"] as? String ?? ""
        var wallet = [String:Any]()
        let prefix = "Unify"
        var primDescriptor = accountMap["descriptor"] as! String
        let blockheight = accountMap["blockheight"] as? Int ?? 0
        
        wallet["id"] = UUID()
        wallet["blockheight"] = Int64(blockheight)
        wallet["maxIndex"] = 999
        wallet["index"] = 0
        
        //var descStruct = Descriptor(primDescriptor)
        
        BitcoinCoreRPC.shared.btcRPC(method: .getnetworkinfo) { (response, errorDesc) in
            guard let response = response as? [String: Any] else {
                completion((false, errorDesc))
                return
            }
            
            let networkInfo = NetworkInfo(dictionary: response)
            self.version = networkInfo.version
            
            if self.version >= 210100 {
                wallet["type"] = "Native-Descriptor"
            }
            
            primDescriptor = primDescriptor.replacingOccurrences(of: "'", with: "h")
            let arr = primDescriptor.split(separator: "#")
            primDescriptor = "\(arr[0])"
            //descStruct = Descriptor(primDescriptor)
            
            
            func createWalletNow(_ recDesc: String, _ changeDesc: String, _ password: String) {
                // Use the sha256 hash of the checksum-less primary receive keypool desc as the wallet name so it has a deterministic identifier
                let walletName = "\(prefix)-\(Crypto.sha256hash(primDescriptor))"
                
                createWallet(walletName, password) { (name, errorMessage) in
                    guard let name = name else {
                        UserDefaults.standard.removeObject(forKey: "walletName")
                        completion((false, "error creatig wallet: \(errorMessage ?? "unknown error")"))
                        return
                    }
                    
                    wallet["name"] = name
                    UserDefaults.standard.set(wallet["name"] as! String, forKey: "walletName")
                    
                    if version >= 210100 {
                        importPrimaryDescriptors(recDesc, changeDesc) { (success, errorMessage) in
                            guard success else {
                                UserDefaults.standard.removeObject(forKey: "walletName")
                                completion((false, "error importing descriptor: \(errorMessage ?? "unknown error")"))
                                return
                            }
                            
                            completion((true, nil))
                        }
                    } else {
                        completion((false, "Unify works with Bitcoin Core 0.21 minimum."))
                    }
                }
            }
            
            getDescriptorInfo(desc: primDescriptor) { (recDesc, errorMessage) in
                guard let recDesc = recDesc else {
                    UserDefaults.standard.removeObject(forKey: "walletName")
                    completion((false, errorMessage ?? "error getting descriptor info"))
                    return
                }
                
                wallet["receiveDescriptor"] = recDesc.replacingOccurrences(of: "'", with: "h")
                
                getDescriptorInfo(desc: primDescriptor.replacingOccurrences(of: "/0/*", with: "/1/*")) { (changeDesc, errorMessage) in
                    guard let changeDesc = changeDesc else {
                        UserDefaults.standard.removeObject(forKey: "walletName")
                        completion((false, errorMessage ?? "error getting change descriptor info"))
                        return
                    }
                    
                    wallet["changeDescriptor"] = changeDesc.replacingOccurrences(of: "'", with: "h")
                    //let hash = Crypto.sha256hash(primDescriptor)
                    createWalletNow(recDesc, changeDesc, password)
                }
            }
        }
    }
    
    
    class func createWallet(_ walletName: String, _ password: String, completion: @escaping ((name: String?, errorMessage: String?)) -> Void) {
        let param = [
            "wallet_name": walletName,
            "avoid_reuse": true,
            "descriptors": true,
            "passphrase": "",
            "load_on_startup": true,
            "disable_private_keys": true
        ] as [String:Any]
        
        let p = Create_Wallet_Param(param)
        BitcoinCoreRPC.shared.btcRPC(method: .createwallet(param: p)) { (response, errDesc) in
            guard let response = response as? [String:Any] else {
                completion((nil, errDesc))
                return
            }
                        
            let warning = response["warning"] as? String
            let walletName = response["name"] as? String
            completion((walletName, warning))
        }
    }
    
    class func importPrimaryDescriptors(_ recDesc: String, _ changeDesc: String, completion: @escaping ((success: Bool, errorMessage: String?)) -> Void) {
        var recDescIsActive = true
        var changeDescIsActive = true
        
        let params:Import_Descriptors = .init([
            "requests":
                [
                    ["desc": recDesc,
                     "active": recDescIsActive,
                     "range": [0,999],
                     "next_index": 0,
                     "timestamp": "now",
                     "internal": false
                    ],
                    [
                        "desc": changeDesc,
                        "active": changeDescIsActive,
                        "range": [0,999],
                        "next_index": 0,
                        "timestamp": "now",
                        "internal": true
                    ]
                ]
        ] as [String:Any])
        
        importDescriptors(params, completion: completion)
    }
    
    class func importDescriptors(_ params: Import_Descriptors, completion: @escaping ((success: Bool, errorMessage: String?)) -> Void) {
        BitcoinCoreRPC.shared.btcRPC(method: .importdescriptors(param: params)) { (response, errorDesc) in
            guard let responseArray = response as? [[String:Any]] else {
                completion((false, "Error importing descriptors: \(errorDesc ?? "unknown error")"))
                return
            }
            
            var warnings:String?
            
            for (i, response) in responseArray.enumerated() {
                var errorMessage = ""
                
                guard let success = response["success"] as? Bool, success else {
                    if let error = response["error"] as? [String:Any], let messageCheck = error["message"] as? String {
                        errorMessage = "Error importing descriptors: \(messageCheck)"
                    }
                    
                    completion((false, errorMessage))
                    return
                }
                
                if let warningsCheck = response["warnings"] as? [String] {
                    warnings = warningsCheck.description
                }
                                
                if i + 1 == responseArray.count {
                    completion((true, warnings))
                }
            }
        }
    }
    
    
    class func getDescriptorInfo(desc: String, completion: @escaping ((desc: String?, errorMessage: String?)) -> Void) {
        let param:Get_Descriptor_Info = .init(["descriptor":desc])
        BitcoinCoreRPC.shared.btcRPC(method: .getdescriptorinfo(param: param)) { (response, errorDesc) in
            guard let response = response as? [String:Any] else {
                completion((nil, errorDesc ?? "Unknown error."))
                return
            }
            
            let descriptorInfo = DescriptorInfo(response)
            completion((desc + "#" + descriptorInfo.checksum, errorDesc))
        }
    }
    
}
