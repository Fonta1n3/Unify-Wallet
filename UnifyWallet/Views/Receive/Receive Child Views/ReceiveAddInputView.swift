//
//  ReceiveAddInputView.swift
//  Unify
//
//  Created by Peter Denton on 6/21/24.
//

import SwiftUI
import LibWally


struct ReceiveAddInputView: View {
    @State private var selection = Set<Utxo>()
    @State private var utxosToSpend: [Utxo] = []
    @State private var spendableAmount = 0.0
    @State private var totalAmtSelected = 0.0
    @State private var errorToDisplay = ""
    @State private var showError = false
    
    
    let invoiceAmount: Double
    let invoiceAddress: String
    let outputAddress: String
    let outputAmount: Double
    let utxos: [Utxo]
    
    var body: some View {
        VStack() {
            List(selection: $selection) {
                Section("Output amount") {
                    Label(outputAmount.btcBalanceWithSpaces, systemImage: "bitcoinsign.circle")
                }
                
                Section() {
                    ForEach(utxos, id:\.self) { utxo in
                        let amt = utxo.amount!.btcBalanceWithSpaces
                        let addr = utxo.address!
                        let txt = addr + " " + amt
                        Text(txt)
                    }
                } header: {
                    Text("Select utxo's to pay the output")
                    
                } footer: {
                    if totalAmtSelected > invoiceAmount {
                        NavigationLink(value: ReceiveNavigationLinkValues.invoiceView(invoiceAmount: invoiceAmount,
                                                                                      invoiceAddress: invoiceAddress,
                                                                                      additionalInputs: utxosToSpend,
                                                                                      utxos: utxos,
                                                                                      outputAddress: outputAddress,
                                                                                      outputAmount: outputAmount)) {
                            
                            Text("Create payjoin invoice")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Text("Select more utxo's to satisfy the output amount.")
                    }
                }
                .onChange(of: selection) {
                    totalAmtSelected = 0.0
                    utxosToSpend.removeAll()
                    
                    for utxo in selection {
                        totalAmtSelected += utxo.amount!
                        utxosToSpend.append(utxo)
                    }
                }
            }
            .onAppear {
                print("hellloooo \(utxos.count)")
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
