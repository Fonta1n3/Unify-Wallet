//
//  ConfigNavigationLinkValues.swift
//  UnifyWallet
//
//  Created by Peter Denton on 7/1/24.
//

import SwiftUI

enum ConfigNavigationLinkValues: Hashable, View {
    
    case configView
    
    var body: some View {
        switch self {
        case .configView:
            return ConfigView()
        }
    }
}



