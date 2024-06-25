//
//  ReceiveAddInputView.swift
//  Unify
//
//  Created by Peter Denton on 6/21/24.
//

import SwiftUI
import LibWally


struct ReceiveAddInputView: View {
    @State private var utxos: [Utxo] = []
    @State private var selection = Set<Utxo>()
    @State private var utxosToSpend: [Utxo] = []
    @State private var spendableAmount = 0.0
    @State private var errorToDisplay = ""
    @State private var showError = false
    @State private var showNavLink = false
    
    
    let invoiceAmount: Double
    let invoiceAddress: String
    
    var body: some View {
        if !showNavLink {
            List(selection: $selection) {
                Section() {
                    ForEach(utxos, id:\.self) { utxo in
                        let amt = utxo.amount!.btcBalanceWithSpaces
                        let addr = utxo.address!
                        let txt = addr + " " + amt
                        Text(txt)
                    }
                    
                } header: {
                    Text("Select UTXOs to Payjoin")
                    
                } footer: {
                    Button {
                        for utxo in selection {
                            utxosToSpend.append(utxo)
                        }
                        showNavLink = true
                    } label: {
                        Text("Next")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            .environment(\.editMode, .constant(EditMode.active))
            #endif
            .alert(errorToDisplay, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
            
            #if os(macOS)
            Text("Hold the command button to select multiple utxos.")
                .foregroundStyle(.secondary)
            #endif
        } else {
            // Show static list with utxosToSpend and navlink button
            Form() {
                List() {
                    Section() {
                        ForEach(utxosToSpend, id:\.self) { utxo in
                            let amt = utxo.amount!.btcBalanceWithSpaces
                            let addr = utxo.address!
                            let txt = addr + " " + amt
                            Text(txt)
                        }
                        
                    } header: {
                        Text("Selected Utxos")
                        
                    } footer: {
                        
                    }
                }
                
                Text("These are the utxo's you selected, select Add Output to proceed.")
                
                Section() {
                    NavigationLink {
                        ReceiveAddOutputView(invoiceAmount: invoiceAmount,
                                             invoiceAddress: invoiceAddress,
                                             additionalInputs: utxosToSpend,
                                             utxos: utxos)
                    } label: {
                        Text("Add Output")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            #endif
            .alert(errorToDisplay, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    
    private func showError(desc: String) {
        errorToDisplay = desc
        showError = true
    }
}
