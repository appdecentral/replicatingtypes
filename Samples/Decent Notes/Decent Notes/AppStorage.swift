//
//  AppStorage.swift
//  Decent Notes
//
//  Created by Drew McCormack on 24/10/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import Foundation

class AppStorage {
    
    let dataStore: DataStore
    let cloudStore: CloudStore
    
    init() {
        dataStore = Self.makeDataStore()
        cloudStore = Self.makeCloudStore(for: dataStore)
        cloudStore.awaken()
    }
    
    func saveAndSync() {
        dataStore.save()
        cloudStore.sync()
    }
    
    func sync() {
        cloudStore.sync()
    }
    
    private static func makeDataStore() -> DataStore {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let subDir = appSupport.appendingPathComponent("DecentNotes")
        return DataStore(directoryURL: subDir)
    }

    private static func makeCloudStore(for dataStore: DataStore) -> CloudStore {
        let recordConfiguration = CloudStore.RecordConfiguration(
            containerIdentifier: "iCloud.com.mentalfaculty.decentnotes",
            zoneName: "NoteBookZone",
            recordType: "NoteBook",
            recordName: "MainNoteBook")
        let cloudStore = CloudStore(recordConfiguration: recordConfiguration, localStorage: dataStore)
        cloudStore.localStorage = dataStore
        return cloudStore
    }

}

