//
//  SelectInputsSendView.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/24/24.
//

import SwiftUI

struct SelectInputsSendView: View {
    @State private var selection = Set<Utxo>()
    @State private var spendableBalance = 0.0
    @State private var selectedUtxosToConsume: [Utxo] = []
    @State private var errorToDisplay = ""
    @State private var showError = false
    @State private var totalAmtSelected = 0.0
    
    let utxos: [Utxo]
    let invoice: Invoice
    
    
    var body: some View {
        VStack() {
            List(selection: $selection) {
                Section("Invoice amount") {
                    Label(invoice.amount!.btcBalanceWithSpaces, systemImage: "bitcoinsign.circle")
                }
                
                Section("Total spendable balance") {
                    Label {
                        Text(spendableBalance.btcBalanceWithSpaces)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Section() {
                    ForEach(utxos, id:\.self) { utxo in
                        Text(utxo.address! + " " + utxo.amount!.btcBalanceWithSpaces)
                            .onAppear {
                                spendableBalance += utxo.amount ?? 0.0
                            }
                    }
                    
                } header: {
                    Text("Select UTXOs to Payjoin")
                    
                } footer: {
                    if totalAmtSelected > invoice.amount! {
                        NavigationLink(value: SendNavigationLinkValues.sendUtxoView(utxos: utxos,
                                                                                    invoice: invoice,
                                                                                    utxosToConsume: selectedUtxosToConsume)) {
                            Text("Pay now")
                        }
                    } else {
                        Text("Select more utxos to satisfy invoice amount.")
                    }
                }
                .onChange(of: selection) {
                    totalAmtSelected = 0.0
                    selectedUtxosToConsume.removeAll()
                    
                    for utxo in selection {
                        totalAmtSelected += utxo.amount!
                        selectedUtxosToConsume.append(utxo)
                    }
                }
            }
            .frame(minHeight: 200)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
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
        }
    }
    
    private func showError(desc: String) {
        errorToDisplay = desc
        showError = true
    }
}
