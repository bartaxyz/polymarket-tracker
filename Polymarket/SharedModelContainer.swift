//
//  SharedModelContainer.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation
import SwiftData

public enum SharedModelContainer {
    public static let container: ModelContainer = {
        let config = ModelConfiguration(
            schema: Schema([WalletConnectModel.self]),
            groupContainer: .identifier("group.com.ondrejbarta.Polymarket"),
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: WalletConnectModel.self, configurations: config)
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }()
}
