//
//  AppDelegate.swift
//  Decent Notes
//
//  Created by Drew McCormack on 03/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import UIKit
import Combine

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    lazy var dataStore: DataStore = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let subDir = appSupport.appendingPathComponent("DecentNotes")
        return DataStore(directoryURL: subDir)
    }()
    
    lazy var cloudStore: CloudStore = {
        let recordConfiguration = CloudStore.RecordConfiguration(
            containerIdentifier: "iCloud.com.mentalfaculty.decentnotes",
            zoneName: "NoteBookZone",
            recordType: "NoteBook",
            recordName: "MainNoteBook")
        let cloudStore = CloudStore(recordConfiguration: recordConfiguration, localStorage: self.dataStore)
        cloudStore.localStorage = self.dataStore
        return cloudStore
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        cloudStore.awaken()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    private var syncCancellable: AnyCancellable?
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let preSyncVersion = dataStore.noteBook.versionId
        syncCancellable = cloudStore.syncPublisher()
            .sink(receiveCompletion: { result in
                let versionChanged = self.dataStore.noteBook.versionId != preSyncVersion
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

