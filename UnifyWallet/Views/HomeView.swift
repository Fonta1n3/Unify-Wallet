//
//  ContentView.swift
//  Pay Join
//
//  Created by Peter Denton on 2/11/24.
//

import SwiftUI
import NostrSDK


enum Tabs: String {
    case receive
    case send
    case history
    case config
}

struct HomeView: View {
    @StateObject private var sendNavigator = Navigator()
    @StateObject private var receiveNavigator = Navigator()
    @State var selectedTab: Tabs = .receive
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $receiveNavigator.path) {
                ReceiveView()
                    .navigationDestination(for: ReceiveNavigationLinkValues.self, destination: { $0 })
            }
            .environmentObject(receiveNavigator)
            .tag(Tabs.receive)
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
            .tag(Tabs.send)
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
                    .navigationDestination(for: HistoryNavigationLinkValues.self, destination: { $0 })
            }
            .tag(Tabs.history)
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
                    .navigationDestination(for: ConfigNavigationLinkValues.self, destination: { $0 })
            }
            .tag(Tabs.config)
            .tabItem {
                Label {
                    Text("Config")
                } icon: {
                    Image(systemName: "gear")
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle(selectedTab.rawValue.capitalized)
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
