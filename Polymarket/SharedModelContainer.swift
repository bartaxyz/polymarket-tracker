//
//  SharedModelContainer.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation
import SwiftData

enum SharedModelContainer {
    static let container: ModelContainer = {
        let config = ModelConfiguration(
            schema: Schema([WalletConnectModel.self]),
            groupContainer: .identifier("group.com.ondrejbarta.Polymarket"),
            cloudKitDatabase: .automatic,
        )
        return try! ModelContainer(for: WalletConnectModel.self, configurations: config)
    }()
}
