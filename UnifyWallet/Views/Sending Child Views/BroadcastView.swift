//
//  BroadcastView.swift
//  Unify
//
//  Created by Peter Denton on 6/18/24.
//

import Foundation
import NostrSDK
import SwiftUI


struct BroadcastView: View, DirectMessageEncrypting {
    @EnvironmentObject private var sendNavigator: Navigator
    @State private var txid: String?
    @State private var sending = false
    @State private var showError = false
    @State private var errorDesc = ""
    @State private var ourKeypair: Keypair? = nil
    @State private var recipientsPublicKey: PublicKey? = nil
    
    
    let hexstring: String
    let invoice: Invoice
    let ourNostrPrivateKey: String
    let recipientsPubkey: String
    
    
    var body: some View {
        if txid == nil {
            if sending {
                VStack() {
                    ProgressView()
                }
                .alert(errorDesc, isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                }
            } else {
                Form() {
                    List() {
                        HStack() {
                            Label("Amount", systemImage: "bitcoinsign")
                            
                            Spacer()
                            
                            Text(invoice.amount!.btcBalanceWithSpaces)
                        }
                        
                        HStack() {
                            Label("Address", systemImage: "arrow.up.forward.circle")
                            
                            Spacer()
                            
                            Text(invoice.address!)
                        }
                        
                        if let _ = ourKeypair, let _ = recipientsPublicKey {
                            HStack() {
                                Spacer()
                                
                                Button("Confirm") {
                                    sending = true
                                    broadcast()
                                }
                                .padding()
                                .buttonStyle(.bordered)
                                
                                Spacer()
                            }
                        }
                        
                        
                        
                        HStack() {
                            Spacer()
                            
                            Text("Tap confirm to broadcast the transaction, this is final.")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                .alert(errorDesc, isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                }
                .onAppear {
                    guard let nostrPrivKey = PrivateKey(hex: ourNostrPrivateKey) else { return }
                    
                    ourKeypair = Keypair(privateKey: nostrPrivKey)
                    recipientsPublicKey = ourKeypair!.publicKey
                }
            }
        } else if let txid = txid {
            Form() {
                HStack() {
                    Spacer()
                    
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .foregroundStyle(.green)
                        .frame(width: 100.0, height: 100.0)
                        .aspectRatio(contentMode: .fit)
                    
                    Spacer()
                }
                
                HStack() {
                    Spacer()
                    
                    Text("Transaction sent ✓")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                HStack() {
                    Label("Txid", systemImage: "note.text")
                        .foregroundStyle(.blue)
                    
                    Text(txid)
                        .foregroundStyle(.secondary)
                        .padding()
                        .truncationMode(.middle)
                        .lineLimit(1)
                    
                    Button {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(txid, forType: .string)
                        #elseif os(iOS)
                        UIPasteboard.general.string = txid
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack() {
                    Spacer()
                    
                    Button {
                        sendNavigator.path.removeLast(sendNavigator.path.count)
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
            .formStyle(.grouped)
            .alert(errorDesc, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    
    private func displayError(desc: String) {
        errorDesc = desc
        showError = true
    }
    
    private func broadcast() {
        let p = Send_Raw_Transaction(["hexstring": hexstring])
        
        BitcoinCoreRPC.shared.btcRPC(method: .sendrawtransaction(p)) { (response, errorDesc) in
            guard let response = response as? String else {
                displayError(desc: errorDesc ?? "Unknown error from sendrawtransaction.")
                
                return
            }
            
            txid = response
            
            
             guard let encEvent = try? encrypt(content: "Payment broadcast by sender ✓",
                                               privateKey: ourKeypair!.privateKey,
                                               publicKey: recipientsPublicKey!) else {
                 displayError(desc: "Encrypting event failed.")
                 
                 return
             }
            
            StreamManager.shared.writeEvent(content: encEvent, recipientNpub: invoice.recipientsNpub!, ourKeypair: ourKeypair!)
        }
    }
}
