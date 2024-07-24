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
    let ourNostrPrivateKey: String?
    let recipientsPubkey: String?
    
    
    var body: some View {
        if txid == nil {
            if sending {
                VStack() {
                    ProgressView()
                    #if os(macOS)
                        .scaleEffect(0.5)
                    #endif
                }
                .alert(errorDesc, isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame (width: 200, height: 200)
                        .clipShape(Circle())
                    
                    Text("Broadcast?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Send \(invoice.amount!.btcBalanceWithSpaces) to \(invoice.address!.withSpaces)? This is final!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    //if let _ = ourKeypair, let _ = recipientsPublicKey {
                        Button("Broadcast") {
                            sending = true
                            broadcast()
                        }
                        .buttonStyle(.borderedProminent)
                    //}
                }
                .padding()
                .alert(errorDesc, isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                }
                .onAppear {
                    if let ourNostrPrivateKey = ourNostrPrivateKey, let recipientsPubkey = recipientsPubkey {
                        guard let nostrPrivKey = PrivateKey(hex: ourNostrPrivateKey) else { return }
                        
                        ourKeypair = Keypair(privateKey: nostrPrivKey)
                        recipientsPublicKey = PublicKey(hex: recipientsPubkey)!
                    }
                    
                }
            }
        } else if let txid = txid {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .foregroundStyle(.green)
                    .frame(width: 200, height: 200.0)
                    .aspectRatio(contentMode: .fit)
                
                Text(txid)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(txid, forType: .string)
                    #elseif os(iOS)
                    UIPasteboard.general.string = txid
                    #endif
                } label: {
                    Label("Copy txid", systemImage: "doc.on.doc")
                    
                }
                .buttonStyle(.bordered)
                    
                Button {
                    sendNavigator.path.removeLast(sendNavigator.path.count)
                } label: {
                    Text("Done")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
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
            
            if let ourKeypair = ourKeypair, let recipientsPublicKey = recipientsPublicKey {
                guard let encEvent = try? encrypt(content: "Payment broadcast by sender ✓",
                                                  privateKey: ourKeypair.privateKey,
                                                  publicKey: recipientsPublicKey) else {
                    displayError(desc: "Encrypting event failed.")
                    
                    return
                }
               
               StreamManager.shared.writeEvent(content: encEvent, recipientNpub: invoice.recipientsNpub!, ourKeypair: ourKeypair)
                
            }
            
        }
    }
}
