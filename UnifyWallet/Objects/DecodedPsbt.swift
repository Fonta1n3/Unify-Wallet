//
//  DecodedPsbt.swift
//  Pay Join
//
//  Created by Peter Denton on 4/26/24.
//

import Foundation



/*
 {                                          (json object)
   "tx" : {                                 (json object) The decoded network-serialized unsigned transaction.
     ...                                    The layout is the same as the output of decoderawtransaction.
   },
   "global_xpubs" : [                       (json array)
     {                                      (json object)
       "xpub" : "str",                      (string) The extended public key this path corresponds to
       "master_fingerprint" : "hex",        (string) The fingerprint of the master key
       "path" : "str"                       (string) The path
     },
     ...
   ],
   "psbt_version" : n,                      (numeric) The PSBT version number. Not to be confused with the unsigned transaction version
   "proprietary" : [                        (json array) The global proprietary map
     {                                      (json object)
       "identifier" : "hex",                (string) The hex string for the proprietary identifier
       "subtype" : n,                       (numeric) The number for the subtype
       "key" : "hex",                       (string) The hex for the key
       "value" : "hex"                      (string) The hex for the value
     },
     ...
   ],
   "unknown" : {                            (json object) The unknown global fields
     "key" : "hex",                         (string) (key-value pair) An unknown key-value pair
     ...
   },
   "inputs" : [                             (json array)
     {                                      (json object)
       "non_witness_utxo" : {               (json object, optional) Decoded network transaction for non-witness UTXOs
         ...
       },
       "witness_utxo" : {                   (json object, optional) Transaction output for witness UTXOs
         "amount" : n,                      (numeric) The value in BTC
         "scriptPubKey" : {                 (json object)
           "asm" : "str",                   (string) Disassembly of the public key script
           "desc" : "str",                  (string) Inferred descriptor for the output
           "hex" : "hex",                   (string) The raw public key script bytes, hex-encoded
           "type" : "str",                  (string) The type, eg 'pubkeyhash'
           "address" : "str"                (string, optional) The Bitcoin address (only if a well-defined address exists)
         }
       },
       "partial_signatures" : {             (json object, optional)
         "pubkey" : "str",                  (string) The public key and signature that corresponds to it.
         ...
       },
       "sighash" : "str",                   (string, optional) The sighash type to be used
       "redeem_script" : {                  (json object, optional)
         "asm" : "str",                     (string) Disassembly of the redeem script
         "hex" : "hex",                     (string) The raw redeem script bytes, hex-encoded
         "type" : "str"                     (string) The type, eg 'pubkeyhash'
       },
       "witness_script" : {                 (json object, optional)
         "asm" : "str",                     (string) Disassembly of the witness script
         "hex" : "hex",                     (string) The raw witness script bytes, hex-encoded
         "type" : "str"                     (string) The type, eg 'pubkeyhash'
       },
       "bip32_derivs" : [                   (json array, optional)
         {                                  (json object)
           "pubkey" : "str",                (string) The public key with the derivation path as the value.
           "master_fingerprint" : "str",    (string) The fingerprint of the master key
           "path" : "str"                   (string) The path
         },
         ...
       ],
       "final_scriptSig" : {                (json object, optional)
         "asm" : "str",                     (string) Disassembly of the final signature script
         "hex" : "hex"                      (string) The raw final signature script bytes, hex-encoded
       },
       "final_scriptwitness" : [            (json array, optional)
         "hex",                             (string) hex-encoded witness data (if any)
         ...
       ],
       "ripemd160_preimages" : {            (json object, optional)
         "hash" : "str",                    (string) The hash and preimage that corresponds to it.
         ...
       },
       "sha256_preimages" : {               (json object, optional)
         "hash" : "str",                    (string) The hash and preimage that corresponds to it.
         ...
       },
       "hash160_preimages" : {              (json object, optional)
         "hash" : "str",                    (string) The hash and preimage that corresponds to it.
         ...
       },
       "hash256_preimages" : {              (json object, optional)
         "hash" : "str",                    (string) The hash and preimage that corresponds to it.
         ...
       },
       "taproot_key_path_sig" : "hex",      (string, optional) hex-encoded signature for the Taproot key path spend
       "taproot_script_path_sigs" : [       (json array, optional)
         {                                  (json object, optional) The signature for the pubkey and leaf hash combination
           "pubkey" : "str",                (string) The x-only pubkey for this signature
           "leaf_hash" : "str",             (string) The leaf hash for this signature
           "sig" : "str"                    (string) The signature itself
         },
         ...
       ],
       "taproot_scripts" : [                (json array, optional)
         {                                  (json object)
           "script" : "hex",                (string) A leaf script
           "leaf_ver" : n,                  (numeric) The version number for the leaf script
           "control_blocks" : [             (json array) The control blocks for this script
             "hex",                         (string) A hex-encoded control block for this script
             ...
           ]
         },
         ...
       ],
       "taproot_bip32_derivs" : [           (json array, optional)
         {                                  (json object)
           "pubkey" : "str",                (string) The x-only public key this path corresponds to
           "master_fingerprint" : "str",    (string) The fingerprint of the master key
           "path" : "str",                  (string) The path
           "leaf_hashes" : [                (json array) The hashes of the leaves this pubkey appears in
             "hex",                         (string) The hash of a leaf this pubkey appears in
             ...
           ]
         },
         ...
       ],
       "taproot_internal_key" : "hex",      (string, optional) The hex-encoded Taproot x-only internal key
       "taproot_merkle_root" : "hex",       (string, optional) The hex-encoded Taproot merkle root
       "unknown" : {                        (json object, optional) The unknown input fields
         "key" : "hex",                     (string) (key-value pair) An unknown key-value pair
         ...
       },
       "proprietary" : [                    (json array, optional) The input proprietary map
         {                                  (json object)
           "identifier" : "hex",            (string) The hex string for the proprietary identifier
           "subtype" : n,                   (numeric) The number for the subtype
           "key" : "hex",                   (string) The hex for the key
           "value" : "hex"                  (string) The hex for the value
         },
         ...
       ]
     },
     ...
   ],
   "outputs" : [                            (json array)
     {                                      (json object)
       "redeem_script" : {                  (json object, optional)
         "asm" : "str",                     (string) Disassembly of the redeem script
         "hex" : "hex",                     (string) The raw redeem script bytes, hex-encoded
         "type" : "str"                     (string) The type, eg 'pubkeyhash'
       },
       "witness_script" : {                 (json object, optional)
         "asm" : "str",                     (string) Disassembly of the witness script
         "hex" : "hex",                     (string) The raw witness script bytes, hex-encoded
         "type" : "str"                     (string) The type, eg 'pubkeyhash'
       },
       "bip32_derivs" : [                   (json array, optional)
         {                                  (json object)
           "pubkey" : "str",                (string) The public key this path corresponds to
           "master_fingerprint" : "str",    (string) The fingerprint of the master key
           "path" : "str"                   (string) The path
         },
         ...
       ],
       "taproot_internal_key" : "hex",      (string, optional) The hex-encoded Taproot x-only internal key
       "taproot_tree" : [                   (json array, optional) The tuples that make up the Taproot tree, in depth first search order
         {                                  (json object, optional) A single leaf script in the taproot tree
           "depth" : n,                     (numeric) The depth of this element in the tree
           "leaf_ver" : n,                  (numeric) The version of this leaf
           "script" : "str"                 (string) The hex-encoded script itself
         },
         ...
       ],
       "taproot_bip32_derivs" : [           (json array, optional)
         {                                  (json object)
           "pubkey" : "str",                (string) The x-only public key this path corresponds to
           "master_fingerprint" : "str",    (string) The fingerprint of the master key
           "path" : "str",                  (string) The path
           "leaf_hashes" : [                (json array) The hashes of the leaves this pubkey appears in
             "hex",                         (string) The hash of a leaf this pubkey appears in
             ...
           ]
         },
         ...
       ],
       "unknown" : {                        (json object, optional) The unknown output fields
         "key" : "hex",                     (string) (key-value pair) An unknown key-value pair
         ...
       },
       "proprietary" : [                    (json array, optional) The output proprietary map
         {                                  (json object)
           "identifier" : "hex",            (string) The hex string for the proprietary identifier
           "subtype" : n,                   (numeric) The number for the subtype
           "key" : "hex",                   (string) The hex for the key
           "value" : "hex"                  (string) The hex for the value
         },
         ...
       ]
     },
     ...
   ],
   "fee" : n                                (numeric, optional) The transaction fee paid if all UTXOs slots in the PSBT have been filled.
 }
 */

public struct DecodedPsbt: CustomStringConvertible {
    let inputs: [[String: Any]]
    let outputs: [[String: Any]]
    let tx: [String: Any]// the unsigned network serialized tx
    let txInputs: [[String: Any]]
    let txLocktime: Int
    let psbtVersion: Int
   
    
    init(_ dictionary: [String: Any]) {
        inputs = dictionary["inputs"] as? [[String: Any]] ?? [[:]]
        outputs = dictionary["outputs"] as? [[String: Any]] ?? []
        tx = dictionary["tx"] as? [String: Any] ?? [:]
        txInputs = tx["vin"] as? [[String: Any]] ?? [[:]]
        psbtVersion = dictionary["psbt_version"] as! Int
        txLocktime = tx["locktime"] as! Int
    }
    
    public var description: String {
        return ""
    }
}

//public struct DecodedPsbtInput: CustomStringConvertible {
//    // non_witness_utxo: the outputs in the non witness utxo are the inputs of our psbt. (can include segwit)
//    
//    // witness_utxo: the "output" the current input is spending from if its segwit
//    
//    let nonWitnessUtxo: [String: Any]
//    let witnessUtxo: [String: Any]
//    
//    /*
//     {
//"bip32_derivs" =                 (
//                     {
//     "master_fingerprint" = e1dd9d1c;
//     path = "m/84'/1'/0'/1/55";
//     pubkey = 030ac5fa6ee00baa2443df3893e289b4320f5492185d9c97fdd4ea5a8c364fbe08;
// }
//);
//"non_witness_utxo" =                 {
// hash = 585466306012ccf1408e952e704e0b81349d022f92d24ac3a91af5496c261ada;
// locktime = 0;
// size = 195;
// txid = 585466306012ccf1408e952e704e0b81349d022f92d24ac3a91af5496c261ada;
// version = 2;
// vin =                     (
//                             {
//         scriptSig =                             {
//             asm = "";
//             hex = "";
//         };
//         sequence = 4294967293;
//         txid = 65f97c58a08c8e36cf09d11fe970af1d3c73fd3e5d4515015ee415ab539dc145;
//         vout = 1;
//     },
//                             {
//         scriptSig =                             {
//             asm = "";
//             hex = "";
//         };
//         sequence = 4294967293;
//         txid = fe5c5587534a27592d3deaf213b3eca7e54ed7811a22d002fcab577b867d476b;
//         vout = 1;
//     },
//                             {
//         scriptSig =                             {
//             asm = "";
//             hex = "";
//         };
//         sequence = 4294967293;
//         txid = 91b3af0f82b7666258e48beb9f9336e016a21d2401169157ca71152efe97ec18;
//         vout = 1;
//     }
// );
// vout =                     (
//                             {
//         n = 0;
//         scriptPubKey =                             {
//             address = tb1qdg32849nweslxr2e70yp6umtwuy4fwulynmrzu;
//             asm = "0 6a22a3d4b37661f30d59f3c81d736b770954bb9f";
//             desc = "addr(tb1qdg32849nweslxr2e70yp6umtwuy4fwulynmrzu)#u0yre8ld";
//             hex = 00146a22a3d4b37661f30d59f3c81d736b770954bb9f;
//             type = "witness_v0_keyhash";
//         };
//         value = "0.003";
//     },
//                             {
//         n = 1;
//         scriptPubKey =                             {
//             address = tb1qwhwxwkqdz02tfflqcw92anxeg06puey2l7ft58;
//             asm = "0 75dc67580d13d4b4a7e0c38aaeccd943f41e648a";
//             desc = "addr(tb1qwhwxwkqdz02tfflqcw92anxeg06puey2l7ft58)#fg5unc9d";
//             hex = 001475dc67580d13d4b4a7e0c38aaeccd943f41e648a;
//             type = "witness_v0_keyhash";
//         };
//         value = "0.00597059";
//     }
// );
// vsize = 195;
// weight = 780;
//};
//"partial_signatures" =                 {
// 030ac5fa6ee00baa2443df3893e289b4320f5492185d9c97fdd4ea5a8c364fbe08 = 304402205d43f0ba32a6d0262264892be8260c07731004238cea332a03da70eacb23e58e02205f2b507ff05162f773caa07bde4f033b35cb41414590513f8fc668444588b51001;
//};
//"witness_utxo" =                 {
// amount = "0.00597059";
// scriptPubKey =                     {
//     address = tb1qwhwxwkqdz02tfflqcw92anxeg06puey2l7ft58;
//     asm = "0 75dc67580d13d4b4a7e0c38aaeccd943f41e648a";
//     desc = "addr(tb1qwhwxwkqdz02tfflqcw92anxeg06puey2l7ft58)#fg5unc9d";
//     hex = 001475dc67580d13d4b4a7e0c38aaeccd943f41e648a;
//     type = "witness_v0_keyhash";
// };
//};
//}
//     */
//}


//public struct DecodedPsbtInputs: CustomStringConvertible {
//    let inputs: [[String: Any]]
//    
//    init(_ dictionary: [[String: Any]]) {
//        inputs = dictionary
//    }
//    
//    public var description: String {
//        return ""
//    }
//}

//public struct DecodedPsbtTx: CustomStringConvertible {
//    let inputs: DecodedPsbtInputs
//    
//    init(_ dictionary: [String: Any]) {
//        inputs = DecodedPsbtInputs(dictionary["vin"] as? [[String: Any]] ?? [[:]])
//    }
//    
//    public var description: String {
//        return ""
//    }
//}

//public struct DecodedPsbtTxInput: CustomStringConvertible {
//    let vout: Int
//    let seq: Int
//    let txid: String
//    
//    init(_ decodedPsbtTx: DecodedPsbtTx) {
//        
//    }
//    
//    public var description: String {
//        return ""
//    }
//}
