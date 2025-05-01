//
//  WalletResolverService.swift
//  Polymarket
//
//  Created by Ondřej Bárta on 1/5/25.
//

#if os(iOS)
import Foundation
import ReownAppKit
import WalletConnectRelay
import Combine
import SwiftData

@Observable
final class WalletResolverService {
    private var bag = Set<AnyCancellable>()
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context

        AppKit.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self,
                      let eip = session.namespaces["eip155"] else { return }
                
                print("sessionSettlePublisher")

                for connectedWalletAddress in eip.accounts.map(\.address) {
                    print(connectedWalletAddress)
                    
                    
                    if hasWallet(connectedWalletAddress) {
                        return
                    }

                    resolvePolygonAddress(for: connectedWalletAddress) { polymarketAddr in
                        Task { @MainActor in
                            guard let polymarketAddr else {
                                return
                            }
                            
                            if self.hasWallet(connectedWalletAddress) {
                                return
                            }
                            
                            context.insert(
                                WalletConnectModel(
                                    walletAddress: connectedWalletAddress,
                                    polymarketAddress: polymarketAddr
                                )
                            )
                            try? context.save()
                        }
                    }
                }

                try? context.save()
            }
            .store(in: &bag)
    }
    
    func getWallet(walletAddress: String) -> [WalletConnectModel] {
        (try? context.fetch(
            FetchDescriptor<WalletConnectModel>(
                predicate: #Predicate<WalletConnectModel> { $0.walletAddress == walletAddress }
            )
        )) ?? []
    }
    
    func hasWallet(_ walletAddress: String) -> Bool {
        !getWallet(walletAddress: walletAddress).isEmpty
    }
    
    func resolvePolygonAddress(
        for eoa: String,
        completion: @escaping (String?) -> Void
    ) {
        let url = URL(string:
          "https://api.fun.xyz/v1/checkout/userId/\(eoa)")!
        print(url)
        URLSession.shared.dataTask(with: url) { data, resp, _ in
            guard
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let jsonArray = try? JSONSerialization.jsonObject(with: data!) as? [[String: Any]],
              let first = jsonArray.first,
              let acct = first["recipientAddr"] as? String
            else {
                print("Not worked :/")
                return completion(nil)
            }
            completion(acct)
        }.resume()
    }
}
#endif
