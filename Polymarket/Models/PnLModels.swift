import Foundation

extension PolymarketModels {

enum PnLInterval: String {
    case max = "max"
    case month = "1m"
    case week = "1w"
    case day = "1d"
    case twelveHours = "12h"
    case sixHours = "6h"
    
    var defaultFidelity: PnLFidelity {
        switch self {
        case .max: return .twelveHours
        case .month: return .threeHours
        case .week: return .threeHours
        case .day, .twelveHours, .sixHours: return .oneHour
        }
    }
}

enum PnLFidelity: String {
    case day = "1d"
    case eighteenHours = "18h"
    case twelveHours = "12h"
    case threeHours = "3h"
    case oneHour = "1h"
}

enum PnLRange: String, CaseIterable {
    case today = "today"
    case day = "1d"
    case week = "1w"
    case month = "1m"
    case max = "max"
    
    var interval: PnLInterval {
        switch self {
        case .max: return .max
        case .month: return .month
        case .week: return .week
        case .day: return .day
        case .today: return .day
        }
    }
    
    var label: String {
        switch self {
        case .max: return "All"
        case .month: return "1M"
        case .week: return "1W"
        case .day: return "1D"
        case .today: return "Today"
        }
    }
}

struct PnLDataPoint: Codable, Equatable {
    var t: Date
    var p: Double
}

} // End of PolymarketModels extension