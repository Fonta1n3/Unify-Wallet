//
//  BitcoinCoreRPC.swift
//  Pay Join
//
//  Created by Peter Denton on 2/11/24.
//

import Foundation

class BitcoinCoreRPC {
    static let shared = BitcoinCoreRPC()
    
    private init() {}
    
    func btcRPC(method: BTC_CLI_COMMAND, completion: @escaping ((response: Any?, errorDesc: String?)) -> Void) {
        let requestId = UUID().uuidString
        
        DataManager.retrieve(entityName: "RPCCredentials") { credentials in
            guard let credentials = credentials, let encRpcPassData = credentials["rpcPass"] as? Data else {
                completion((nil, "No credentials saved."))
                return
            }
            
            guard let decRpcPass = Crypto.decrypt(encRpcPassData) else {
                completion((nil, "Unable to decrypt rpc pass."))
                return
            }
            
            guard let rpcPass = String(data: decRpcPass, encoding: .utf8) else {
                completion((nil, "Unable to get text of rpc pass."))
                return
            }
            
            guard let rpcUser = credentials["rpcUser"] as? String else {
                completion((nil, "Unable to get rpc user."))
                return
            }

            guard let rpcPort = credentials["rpcPort"] as? String else {
                completion((nil, "Unable to get rpcPort."))
                return
            }
            
            let rpcAddress = credentials["rpcAddress"] as? String ?? "localhost"
            
            let walletName = UserDefaults.standard.object(forKey: "walletName") as? String
            var walletUrl = "http://\(rpcUser):\(rpcPass)@\(rpcAddress):\(rpcPort)"
            
            if !(method.stringValue == "listwallets") {
                if let walletName = walletName {
                    walletUrl += "/wallet/" + walletName
                }
            }
                        
            guard let url = URL(string: walletUrl) else {
                completion((nil, "URL error."))
                return
            }
            
            var request = URLRequest(url: url)
            let timeout = 60.0
            
//            switch method.stringValue {
//            case "gettxoutsetinfo":
//                timeout = 1000.0
//                
//            case "importmulti", "deriveaddresses", "loadwallet":
//                timeout = 60.0
//                
//            default:
//                break
//            }
            
            let loginString = String(format: "%@:%@", "PayJoin", rpcPass)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let base64LoginString = loginData.base64EncodedString()
            request.timeoutInterval = timeout
            request.httpMethod = "POST"
            request.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            
            let dict:[String:Any] = ["jsonrpc": "1.0","id": requestId,"method": method.stringValue,"params": method.paramDict]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) else {
                #if DEBUG
                print("converting to jsonData failing...")
                #endif
                completion((nil, "JSON error."))
                return
            }
            
            request.httpBody = jsonData
            
            #if DEBUG
            print("url = \(url)")
            print("request: \(dict)")
            #endif
            var session = URLSession(configuration: .default)
            
            if rpcAddress.hasSuffix(".onion") {
                session = TorClient.sharedInstance.session
            }
            
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
                guard let urlContent = data else {
                    guard let error = error else {
                        completion((nil, "Unknown error."))
                        return
                    }
                    completion((nil, error.localizedDescription))
                    return
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: urlContent, options: .mutableLeaves) as? NSDictionary else {
                    if let httpResponse = response as? HTTPURLResponse {
                        switch httpResponse.statusCode {
                        case 401:
                            completion((nil, "Looks like your rpc credentials are incorrect. Make sure to add your rpc authentication string to your bitcoin.conf, restart your node and try again."))
                        case 403:
                            completion((nil, "The bitcoin-cli \(method) command has not been added to your rpcwhitelist, add \(method) to your bitcoin.conf rpcwhitelsist, reboot Bitcoin Core and try again."))
                        default:
                            completion((nil, "Unable to decode the response from your node, http status code: \(httpResponse.statusCode)"))
                        }
                    } else {
                        completion((nil, "Unable to decode the response from your node..."))
                    }
                    return
                }
                
                #if DEBUG
                print("json: \(json)")
                #endif
                
                guard let errorCheck = json["error"] as? NSDictionary else {
                    completion((json["result"], nil))
                    return
                }
                
                guard let errorMessage = errorCheck["message"] as? String else {
                    completion((nil, "Uknown error from bitcoind"))
                    return
                }
                
                completion((nil, errorMessage))
            }
            
            task.resume()
        }
    }
}
