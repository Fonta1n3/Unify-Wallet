//
//  ContentView.swift
//  Pay Join
//
//  Created by Peter Denton on 2/11/24.
//

import SwiftUI
import NostrSDK

struct HomeView: View {
    @StateObject private var sendNavigator = Navigator()
    @StateObject private var receiveNavigator = Navigator()
    
    
    var body: some View {
        TabView() {
            NavigationStack(path: $receiveNavigator.path) {
                ReceiveView()
                    .navigationDestination(for: ReceiveNavigationLinkValues.self, destination: { $0 })
                    .navigationTitle("Receive")
            }
            .environmentObject(receiveNavigator)
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
                    .navigationTitle("Send")
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
            
            NavigationStack() {
                HistoryView()
                    .navigationTitle("History")
                    .navigationDestination(for: HistoryNavigationLinkValues.self, destination: { $0 })
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
                    .navigationTitle("Config")
                    .navigationDestination(for: ConfigNavigationLinkValues.self, destination: { $0 })
            }
            .tabItem {
                Label {
                    Text("Config")
                } icon: {
                    Image(systemName: "gear")
                        .foregroundStyle(.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
        
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
