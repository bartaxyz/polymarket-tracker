//
//  DefaultSocketFactory.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

#if os(iOS)
import Foundation
import WalletConnectRelay
import Starscream

extension WebSocket: WebSocketConnecting { }

struct DefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}
#endif
