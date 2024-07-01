//
//  HistoryNavigationLinkValues.swift
//  UnifyWallet
//
//  Created by Peter Denton on 7/1/24.
//

import SwiftUI

enum HistoryNavigationLinkValues: Hashable, View {
    
    case historyView
    
    var body: some View {
        switch self {
        case .historyView:
            return HistoryView()
        }
    }
}
