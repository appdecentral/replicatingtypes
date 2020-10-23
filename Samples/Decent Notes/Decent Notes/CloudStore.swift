//
//  CloudStore.swift
//  Decent Notes
//
//  Created by Drew McCormack on 05/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import Foundation
import CloudKit
import Combine
import UIKit

protocol LocalStorage: class {
    func receiveDownload(from store: CloudStore, _ data: Data)
    func shouldUpload(to store: CloudStore) -> Bool
    func dataToUpload(to store: CloudStore) throws -> Data
}

/// This is a handy class for managing a CloudKit record, and keeping it up-to-date
/// with some local resource, such as a file.
class CloudStore {
    
    // MARK:- Errors

    enum Error: Swift.Error {
        case zoneIsMissing
        case noLocalStorage
    }
    
    // MARK:- Record Properties
    
    struct RecordConfiguration {
        var containerIdentifier: String
        var zoneName: String
        var recordType: String
        var recordName: String
        var subscriptionId: CKSubscription.ID? = nil
    }
    
    // MARK:- Properties
    
    weak var localStorage: LocalStorage?
    let container: CKContainer
    let database: CKDatabase
    let recordConfiguration: RecordConfiguration
    
    private var zone: CKRecordZone?
    private let zoneId: CKRecordZone.ID
    private let recordType: CKRecord.RecordType
    private let recordId: CKRecord.ID
    private var record: CKRecord?
    private let dataKeyName: String = "data"
    private var serverToken: CKServerChangeToken?
    
    // MARK:- Init and Awaken
    
    init(recordConfiguration: RecordConfiguration, localStorage: LocalStorage) {
        self.container = CKContainer(identifier: recordConfiguration.containerIdentifier)
        self.database = self.container.privateCloudDatabase
        self.recordConfiguration = recordConfiguration
        self.zoneId = .init(zoneName: recordConfiguration.zoneName, ownerName: CKCurrentUserDefaultName)
        self.recordType = .init(recordConfiguration.recordType)
        self.recordId = .init(recordName: recordConfiguration.recordName, zoneID: zoneId)
        subscribeToPush()
        pollCloudForChanges()
        awaken()
    }
    
    func awaken() {
        if zone == nil {
            setupZoneSubscription = setupZone()
            DispatchQueue.main.asyncAfter(deadline: .now()+5.0) {
                self.sync()
            }
        }
    }
    
    // MARK:- Setup Zone
    
    private var setupZoneSubscription: AnyCancellable?
    func setupZone() -> AnyCancellable {
        retrieveZone()
            .catch { _ in self.retrieveZone().delay(for: 10, scheduler: DispatchQueue.main) } // If error, delay and retry
            .retry(3)
            .map { CKRecordZone?.init($0) }
            .replaceError(with: nil) // We are giving up. Just set zone to nil
            .receive(on: RunLoop.main)
            .assign(to: \.zone, on: self)
    }
    
    func retrieveZone() -> AnyPublisher<CKRecordZone, Swift.Error> {
        let fetchZone = Future<CKRecordZone?, Swift.Error> { [unowned self] promise in
            self.database.fetch(withRecordZoneID: self.zoneId) { zone, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(zone))
                }
            }
        }
        
        let createZone = Future<CKRecordZone, Swift.Error> { [unowned self] promise in
            let newZone = CKRecordZone(zoneID: self.zoneId)
            let operation = CKModifyRecordZonesOperation(recordZonesToSave: [newZone], recordZoneIDsToDelete: nil)
            operation.modifyRecordZonesCompletionBlock = { savedZones, _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(savedZones!.first!))
                }
            }
            self.database.add(operation)
        }
        
        return fetchZone
            .flatMap { existingZone -> AnyPublisher<CKRecordZone, Swift.Error> in
                if let existingZone = existingZone {
                    return Result<CKRecordZone, Swift.Error>.Publisher(.success(existingZone)).eraseToAnyPublisher()
                } else {
                    return createZone.eraseToAnyPublisher()
                }
            }.eraseToAnyPublisher()
    }
    
    // MARK:- Sync
    
    private var syncSubscription: AnyCancellable?
    func sync() {
        let background = UIApplication.shared.beginBackgroundTask {
            self.syncSubscription?.cancel()
        }
        self.syncSubscription = self.syncPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Failed to sync: \(error)")
                case .finished:
                    print("Sync completed")
                }
                UIApplication.shared.endBackgroundTask(background)
            }, receiveValue: {})
    }
    
    func syncPublisher() -> AnyPublisher<Void, Swift.Error> {
        let downloadPublisher: AnyPublisher<ServerDownload, Swift.Error>
        if zone != nil {
            downloadPublisher = self.downloadPublisher().eraseToAnyPublisher()
        } else {
            downloadPublisher = retrieveZone().flatMap { zone -> AnyPublisher<ServerDownload, Swift.Error> in
                self.zone = zone
                return self.downloadPublisher()
            }.eraseToAnyPublisher()
        }
        
        return downloadPublisher
            .receive(on: RunLoop.main)
            .flatMap { (serverDownload: ServerDownload) -> AnyPublisher<Void, Swift.Error> in
                if let record = serverDownload.record {
                    self.record = record
                    if let data = record[self.dataKeyName] as? Data {
                        self.localStorage?.receiveDownload(from: self, data)
                    }
                }
                if self.localStorage != nil {
                    self.serverToken = serverDownload.serverToken
                }
                return Result<Void, Swift.Error>.Publisher(.success(()))
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .flatMap { existingRecord -> AnyPublisher<Void, Swift.Error> in
                do {
                    guard let localStorage = self.localStorage else { throw Error.noLocalStorage }
                    if localStorage.shouldUpload(to: self) {
                        let data = try localStorage.dataToUpload(to: self)
                        return self.uploadPublisher(forData: data)
                            .map { _ in () }
                            .eraseToAnyPublisher()
                    } else {
                        return Result<Void, Swift.Error>.Publisher(())
                            .eraseToAnyPublisher()
                    }
                } catch {
                     return Result<Void, Swift.Error>.Publisher(.failure(error))
                         .eraseToAnyPublisher()
                }
            }.eraseToAnyPublisher()
    }
    
    private struct ServerDownload {
        var record: CKRecord?
        var serverToken: CKServerChangeToken?
    }
    
    // MARK:- Upload and Download
    
    private func downloadPublisher() -> AnyPublisher<ServerDownload, Swift.Error> {
        Future<ServerDownload, Swift.Error> { [unowned self] promise in
            guard let zone = self.zone else {
                promise(.failure(Error.zoneIsMissing))
                return
            }
            
            let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            config.previousServerChangeToken = self.serverToken
            
            var downloadedRecord: CKRecord?
            var serverToken: CKServerChangeToken?
            let operation = CKFetchRecordZoneChangesOperation()
            operation.recordZoneIDs = [zone.zoneID]
            operation.configurationsByRecordZoneID = [zone.zoneID : config]
            operation.fetchAllChanges = true
            operation.recordChangedBlock = { record in
                if record.recordID == self.recordId {
                    downloadedRecord = record
                }
            }
            operation.recordZoneFetchCompletionBlock = { _, token, _, _, error in
                if error == nil { serverToken = token }
            }
            operation.fetchRecordZoneChangesCompletionBlock = { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let download = ServerDownload(record: downloadedRecord, serverToken: serverToken)
                    promise(.success(download))
                }
            }
            self.database.add(operation)
        }.eraseToAnyPublisher()
    }

    private func uploadPublisher(forData data: Data) -> AnyPublisher<CKRecord, Swift.Error> {
        Future<CKRecord, Swift.Error> { promise in
            let record = self.record ?? CKRecord(recordType: self.recordType, recordID: self.recordId)
            record[self.dataKeyName] = data
            
            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(savedRecords!.first!))
                }
            }
            self.database.add(operation)
        }.eraseToAnyPublisher()
    }
    
    // MARK:- Scheduling Syncs
    
    func subscribeToPush() {
        guard let subscriptionId = recordConfiguration.subscriptionId else { return }
        
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionId, options: CKQuerySubscription.Options.firesOnRecordCreation)
        subscription.notificationInfo = info
        
        database.save(subscription) { (_, error) in
            if let error = error {
                print("Error creating subscription: \(error)")
            }
        }
    }
    
    private var pollingSubscription: AnyCancellable?
    
    /// If the push is working, we shoudln't need this, but just in case, we poll for new changes occasionally.
    func pollCloudForChanges() {
        pollingSubscription = Timer.publish(every: 20, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.sync()
            }
    }
}


