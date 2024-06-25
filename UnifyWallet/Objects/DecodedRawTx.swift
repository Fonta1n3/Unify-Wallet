//
//  DecodedRawTx.swift
//  Unify
//
//  Created by Peter Denton on 6/22/24.
//

import Foundation
/*
 {                             (json object)
   "txid" : "hex",             (string) The transaction id
   "hash" : "hex",             (string) The transaction hash (differs from txid for witness transactions)
   "size" : n,                 (numeric) The serialized transaction size
   "vsize" : n,                (numeric) The virtual transaction size (differs from size for witness transactions)
   "weight" : n,               (numeric) The transaction's weight (between vsize*4-3 and vsize*4)
   "version" : n,              (numeric) The version
   "locktime" : xxx,           (numeric) The lock time
   "vin" : [                   (json array)
     {                         (json object)
       "coinbase" : "hex",     (string, optional) The coinbase value (only if coinbase transaction)
       "txid" : "hex",         (string, optional) The transaction id (if not coinbase transaction)
       "vout" : n,             (numeric, optional) The output number (if not coinbase transaction)
       "scriptSig" : {         (json object, optional) The script (if not coinbase transaction)
         "asm" : "str",        (string) Disassembly of the signature script
         "hex" : "hex"         (string) The raw signature script bytes, hex-encoded
       },
       "txinwitness" : [       (json array, optional)
         "hex",                (string) hex-encoded witness data (if any)
         ...
       ],
       "sequence" : n          (numeric) The script sequence number
     },
     ...
   ],
   "vout" : [                  (json array)
     {                         (json object)
       "value" : n,            (numeric) The value in BTC
       "n" : n,                (numeric) index
       "scriptPubKey" : {      (json object)
         "asm" : "str",        (string) Disassembly of the public key script
         "desc" : "str",       (string) Inferred descriptor for the output
         "hex" : "hex",        (string) The raw public key script bytes, hex-encoded
         "address" : "str",    (string, optional) The Bitcoin address (only if a well-defined address exists)
         "type" : "str"        (string) The type (one of: nonstandard, pubkey, pubkeyhash, scripthash, multisig, nulldata, witness_v0_scripthash, witness_v0_keyhash, witness_v1_taproot, witness_unknown)
       }
     },
     ...
   ]
 }
 */

public struct DecodedRawTx: CustomStringConvertible {
    var inputs: [DecodedRawTxInput] = []
    
    init(_ dictionary: [String: Any]) {
        let vin = dictionary["vin"] as! [[String: Any]]
        for input in vin {
            inputs.append(DecodedRawTxInput(input))
        }
        
    }
    
    public var description: String {
        return ""
    }
}


public struct DecodedRawTxInput: CustomStringConvertible {
    let txid: String
    let vout: Int
    let sequence: Int
    
    init(_ dictionary: [String: Any]) {
        txid = dictionary["txid"] as! String
        vout = dictionary["vout"] as! Int
        sequence = dictionary["sequence"] as! Int
    }
    
    public var description: String {
        return ""
    }
}


