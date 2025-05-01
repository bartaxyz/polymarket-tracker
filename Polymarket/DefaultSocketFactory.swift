//
//  DefaultSocketFactory.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

import Foundation
import WalletConnectRelay
import Starscream

extension WebSocket: WebSocketConnecting { }

struct DefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("ondrejbarta.com", forHTTPHeaderField: "Origin")
        return WebSocket(request: urlRequest)
    }
}
