import Foundation

extension PolymarketModels {

struct Position: Codable {
    let proxyWallet: String
    let asset: String
    let conditionId: String
    let size: Double
    let avgPrice: Double
    let initialValue: Double
    let currentValue: Double
    let cashPnl: Double
    let percentPnl: Double
    let totalBought: Double
    let realizedPnl: Double
    let percentRealizedPnl: Double
    let curPrice: Double
    let redeemable: Bool
    let mergeable: Bool
    let title: String
    let slug: String
    let icon: String
    let eventSlug: String
    let outcome: String
    let outcomeIndex: Int
    let oppositeOutcome: String
    let oppositeAsset: String
    let endDate: String
    let negativeRisk: Bool
}

} // End of PolymarketModels extension