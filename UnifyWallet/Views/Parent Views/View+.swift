//
//  View+.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/24/24.
//

import SwiftUI

extension View {
    func navigationLinkValues<D>(_ Data: D.Type) -> some View where D : Hashable & View {
        NavigationStack {
            self.navigationDestination(for: Data, destination: { $0 })
        }
    }
}
