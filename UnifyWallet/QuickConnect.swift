//
//  QuickConnect.swift
//  UnifyWallet
//
//  Created by Peter Denton on 8/26/24.
//

import Foundation

class QuickConnect {
    
    // MARK: QuickConnect uri examples
    /// btcrpc://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:8332/?label=Node%20Name
    /// btcrpc://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:18332/?
    /// btcrpc://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:18443
        
    class func addNode(url: String, completion: @escaping ((success: Bool, errorMessage: String?)) -> Void) {
        
        
        guard let host = URLComponents(string: url)?.host,
              let port = URLComponents(string: url)?.port else {
            completion((false, "invalid url"))
            return
        }
                
        guard let rpcPassword = URLComponents(string: url)?.password,
              let rpcUser = URLComponents(string: url)?.user else {
            completion((false, "No RPC credentials."))
            return
        }
                
        guard host != "", rpcUser != "", rpcPassword != "" else {
            completion((false, "Either the hostname, rpcuser or rpcpassword is empty."))
            return
        }
        
        // Encrypt credentials
        guard let encPass = Crypto.encrypt(rpcPassword.dataUsingUTF8StringEncoding) else {
            completion((false, "Error encrypting your credentials."))
            return
        }
        
        let newNode: [String: Any] = [
            "rpcAddress": host,
            "rpcUser": rpcUser,
            "rpcPort": "\(port)",
            "rpcPass": encPass
        ]
        
        saveNode(newNode, url, completion: completion)
    }
    
    private class func saveNode(_ node: [String:Any], _ url: String, completion: @escaping ((success: Bool, errorMessage: String?)) -> Void) {
        DataManager.deleteAllData(entityName: "RPCCredentials") { deleted in
            DataManager.saveEntity(entityName: "RPCCredentials", dict: node) { saved in
                guard saved else {
                    completion((false, "Unable to save rpc credentials."))
                    return
                }
                
                completion((true, nil))
            }
        }
    }
}

extension URL {
    func value(for paramater: String) -> String? {
        let queryItems = URLComponents(string: self.absoluteString)?.queryItems
        let queryItem = queryItems?.filter({$0.name == paramater}).first
        let value = queryItem?.value
        return value
    }
}
