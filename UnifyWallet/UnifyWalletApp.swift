//
//  UnifyWalletApp.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/24/24.
//

import SwiftUI

@main
struct UnifyWalletApp: App {
    @StateObject private var manager: DataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(manager)
                .environment(\.managedObjectContext, manager.container.viewContext)
        }
    }
}
