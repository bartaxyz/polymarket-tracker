//
//  PolymarketApp.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 27/4/25.
//

import SwiftUI
import SwiftData
import ReownWalletKit
import ReownAppKit
import WalletConnectSign
import ReownAppKit

@main
struct PolymarketApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WalletConnectModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        let metadata = AppMetadata(
          name: "Polymarket Widgets",
          description: "Widgets for Polymarket",
          url: "https://github.com/bartaxyz/polymarket-widgets",
          icons: ["https://…/icon.png"],
          redirect: try! AppMetadata.Redirect(
            native: "polymarketwidgets://",
            universal: "https://ondrejbarta.com"
          ),
        )

        Networking.configure(
            groupIdentifier: "group.com.ondrejbarta.Polymarket",
            projectId: "4e5776558e4e0d164b7bb6a3227d7da5",
            socketFactory: DefaultSocketFactory()
        )

        AppKit.configure(
          projectId: "4e5776558e4e0d164b7bb6a3227d7da5",
          metadata: metadata,
          crypto: DefaultCryptoProvider(),
          authRequestParams: nil,
        )
    }

    var body: some Scene {
        WindowGroup {
            WalletConnectView()
        }
        .modelContainer(sharedModelContainer)
    }
}
