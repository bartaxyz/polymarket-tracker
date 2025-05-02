//
//  PolymarketDataService.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation

class PolymarketDataService {
    
    /**
     * Fetch Portfolio
     * ```
     * GET https://data-api.polymarket.com/value?user=<user_id>
     * [{
     *   "user": "0x235a480a9ccb7ada0ad2dc11dac3a11fb433febd",
     *   "value": 1209.4328514150002,
     * }]
     * ```
     */
    static func fetchPortfolio(userId: String) async throws -> Double {
        let url = URL(string: "https://data-api.polymarket.com/value?user=\(userId)")!
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
        return json[0]["value"] as! Double
    }

    /**
     * Fetch PnL
     * ```
     * GET https://user-pnl-api.polymarket.com/user-pnl?user_address=<user_id>&interval=1w&fidelity=3h
     * [{"t":1745971200,"p":317.79596}, ...
     * ```
     */
    enum PnLInterval: String {
        case max = "max"
        case month = "1m"
        case week = "1w"
        case day = "1d"
        case twelveHours = "12h"
        case sixHours = "6h"
    }
    enum PnLFidelity: String {
        case day = "1d"
        case eighteenHours = "18h"
        case twelveHours = "12h"
        case threeHours = "3h"
        case oneHour = "1h"
    }
    struct PnLRawDataPoint: Decodable {
        let t: Int
        let p: String
    }
    struct PnLDataPoint: Decodable {
        let t: Date
        let p: Double
    }
    static func fetchPnL(userId: String, interval: PnLInterval = .day, fidelity: PnLFidelity = .oneHour) async throws -> [PnLDataPoint] {
        let url = URL(string: "https://user-pnl-api.polymarket.com/user-pnl?user_address=\(userId)&interval=\(interval.rawValue)&fidelity=\(fidelity.rawValue)")!
        print(url)
        let data  = try Data(contentsOf: url)
        guard let raw = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        
        print(data)

        return raw.compactMap { dict in
            guard let t = dict["t"] as? Int else { return nil }

            // p might be Double or String
            let p: Double
            if let num = dict["p"] as? Double {
                p = num
            } else if let str = dict["p"] as? String, let num = Double(str) {
                p = num
            } else {
                return nil
            }

            return PnLDataPoint(
                t: Date(timeIntervalSince1970: TimeInterval(t)),
                p: p
            )
        }
    }
}
