//
//  WalletEntity.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

/*
import AppIntents
import SwiftData
import WidgetKit

public struct WalletEntity: AppEntity, Identifiable, Hashable {
    public static var defaultQuery = WalletQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Wallet")

    public var id: String
    public let displayAddress: String

    // Internal init with WalletConnectModel
    init(model: WalletConnectModel) {
        self.id = model.polymarketAddress!
        self.displayAddress = model.compressedPolymarketAddress!
    }
    
    public init(id: String, displayAddress: String) {
        self.id = id
        self.displayAddress = displayAddress
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayAddress)")
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: WalletEntity, rhs: WalletEntity) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Picker data source
public struct WalletQuery: EntityQuery {
    public init() {}
    
    @MainActor
    public func entities(for identifiers: [String]) async throws -> [WalletEntity] {
        let ctx = SharedModelContainer.container.mainContext
        let wallets = try ctx.fetch(
            FetchDescriptor<WalletConnectModel>(
                predicate: #Predicate { identifiers.contains($0.polymarketAddress!) }
            )
        )
        return wallets.map(WalletEntity.init)
    }

    @MainActor
    public func suggestedEntities() async throws -> [WalletEntity] {
        let ctx = SharedModelContainer.container.mainContext
        let wallets = try ctx.fetch(FetchDescriptor<WalletConnectModel>())
        return wallets.map(WalletEntity.init)
    }
}

private extension WalletConnectModel {
    @MainActor
    static func fetchAll() throws -> [WalletConnectModel] {
        let ctx = SharedModelContainer.container.mainContext
        return try ctx.fetch(FetchDescriptor<WalletConnectModel>())
    }

    @MainActor
    static func fetch(byIDs ids: [PersistentIdentifier]) throws -> [WalletConnectModel] {
        let ctx = SharedModelContainer.container.mainContext
        return try ctx.fetch(
            FetchDescriptor(
                predicate: #Predicate<WalletConnectModel> { ids.contains($0.persistentModelID) }
            )
        )
    }
}
*/
