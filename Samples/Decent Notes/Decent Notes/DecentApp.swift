//
//  AppDelegate.swift
//  Decent Notes
//
//  Created by Drew McCormack on 03/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import SwiftUI
import Combine

@main struct DecentApp: App {
    @Environment(\.scenePhase) private var phase
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    let storage = AppStorage()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storage.dataStore)
                .accentColor(.purple)
                .onAppear {
                    appDelegate.storage = self.storage
                }
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .active:
                storage.sync()
            case .inactive:
                storage.saveAndSync()
            case .background:
                storage.saveAndSync()
            @unknown default:
                break
            }
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    public var storage: AppStorage?

    private var syncCancellable: AnyCancellable?
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let storage = self.storage else { return }
        let preSyncVersion = storage.dataStore.noteBook.versionId
        syncCancellable = storage.cloudStore.syncPublisher()
            .sink(receiveCompletion: { result in
                let versionChanged = storage.dataStore.noteBook.versionId != preSyncVersion
                switch result {
                case .failure(let error):
                    print("Error during sync \(error)")
                    completionHandler(.failed)
                case .finished:
                    let result: UIBackgroundFetchResult = versionChanged ? .newData : .noData
                    completionHandler(result)
                }
            }, receiveValue: {})
    }
}

