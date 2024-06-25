//
//  ContentView.swift
//  Pay Join
//
//  Created by Peter Denton on 2/11/24.
//

import SwiftUI
import NostrSDK

struct HomeView: View {
    @State private var showNotSavedAlert = false
    @State private var showSavedAlert = false
    @StateObject private var sendNavigator = Navigator()
    
    var body: some View {
        TabView() {
            NavigationStack() {
                ReceiveView()
            }
            .tabItem {
                Label {
                    Text("Receive")
                } icon: {
                    Image(systemName: "arrow.down.forward.circle")
                        .foregroundStyle(.blue)
                }
            }
            
            NavigationStack(path: $sendNavigator.path) {
                SendView()
                    .navigationDestination(for: SendNavigationLinkValues.self, destination: { $0 })
            }
            .environmentObject(sendNavigator)
            .tabItem {
                Label {
                    Text("Send")
                } icon: {
                    Image(systemName: "arrow.up.forward.circle")
                        .foregroundStyle(.blue)
                }
            }
            
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label {
                    Text("History")
                } icon: {
                    Image(systemName: "clock")
                        .foregroundStyle(.blue)
                }
            }
            
            NavigationStack {
                ConfigView()
            }
            .tabItem {
                Label {
                    Text("Config")
                } icon: {
                    Image(systemName: "gear")
                        .foregroundStyle(.blue)
                }
            }

            
            //HistoryView()
            
//            NavigationLink {
//                HistoryView()
//                
//            } label: {

//            }
            
            //ConfigView()
//            NavigationLink {
//                ConfigView()
//                
//            } label: {
//                Label {
//                    Text("Config")
//                } icon: {
//                    Image(systemName: "gear")
//                        .foregroundStyle(.blue)
//                }
//            }
        }
                
            //}
            .navigationTitle("Unify")
        //}
        .preferredColorScheme(.dark)
        .alert(CoreDataError.notSaved.localizedDescription, isPresented: $showNotSavedAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            DispatchQueue.global(qos: .background).async {
                createDefaultCreds()
            }
        }
    }
    
    
    private func createDefaultCreds() {
        DataManager.retrieve(entityName: "Credentials") { credentials in
            guard let _ = credentials else {
                
                guard KeyChain.set(Crypto.privKeyData(), forKey: "encKeyUnify") else {
                    showNotSavedAlert = true
                    return
                }
                
                guard let rpcauthcreds = RPCAuth().generateCreds(username: "Unify", password: nil) else {
                    showNotSavedAlert = true
                    return
                }
                
                UserDefaults.standard.setValue("38332", forKey: "rpcPort")
                UserDefaults.standard.setValue("Signet", forKey: "network")
                
                let rpcpass = rpcauthcreds.password
                
                guard let encRpcPass = Crypto.encrypt(rpcpass.data(using: .utf8)!) else {
                    showNotSavedAlert = true
                    return
                }
                                
                let dict: [String:Any] = [
                    "rpcPass": encRpcPass,
                    "rpcUser": "Unify"
                ]
                
                saveCreds(dict: dict)
                
                return
            }
        }
    }
    
    private func saveCreds(dict: [String: Any]) {
        DataManager.saveEntity(entityName: "Credentials", dict: dict) { saved in
            guard saved else {
                showNotSavedAlert = true
                return
            }
            
            showSavedAlert = true
        }
    }
}


class Navigator: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(with model: any Hashable) {
        path.append(model)
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
