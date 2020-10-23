//
//  DataStore.swift
//  Decent Notes
//
//  Created by Drew McCormack on 03/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import Foundation
import SwiftUI

class DataStore: ObservableObject {
    
    struct Metadata: Codable {
        var versionOfNotebookInCloud: UUID?
    }
     
    @Published var noteBook: NoteBook
    
    var metadata: Metadata
    let metadataFileURL: URL
    
    let directoryURL: URL
    let storeFileURL: URL
    
    var notesCount: Int {
        Int(noteBook.notes.count)
    }
    
    init(directoryURL: URL) {
        // Create directory for data
        self.directoryURL = directoryURL
        try? FileManager.default.createDirectory(at: self.directoryURL, withIntermediateDirectories: true, attributes: nil)
        
        // Load metadata
        metadataFileURL = self.directoryURL.appendingPathComponent("Metadata.json")
        if FileManager.default.fileExists(atPath: metadataFileURL.path) {
            metadata = try! JSONDecoder().decode(Metadata.self, from: Data(contentsOf: metadataFileURL))
        } else {
            metadata = Metadata()
        }
        
        // Load data or create new notebook
        storeFileURL = self.directoryURL.appendingPathComponent("DataStore.json")
        if FileManager.default.fileExists(atPath: storeFileURL.path) {
            noteBook = try! JSONDecoder().decode(NoteBook.self, from: Data(contentsOf: storeFileURL))
        } else {
            noteBook = NoteBook()
        }
    }
    
    // MARK:- Save and Merge
    
    func save() {
        try! JSONEncoder().encode(noteBook).write(to: storeFileURL)
        try! JSONEncoder().encode(metadata).write(to: metadataFileURL)
    }
    
    func merge(cloudNotebook: NoteBook) {
        metadata.versionOfNotebookInCloud = cloudNotebook.versionId
        noteBook = noteBook.merged(with: cloudNotebook)
        save()
    }
    
    // MARK:- Updating Notes
    
    func addNote() {
        noteBook.append(Note())
    }
    
    func deleteNote(at index: Int) {
        noteBook.remove(at: index)
    }
    
    // MARK:- Bindings
    
    func noteBinding(forId id: Note.ID) -> Binding<Note> {
        .init(
            get: { () -> Note in
                self.noteBook.notes.first(where: { $0.id == id })!
            },
            set: { note in
                let i = self.noteBook.notes.firstIndex(where: { $0.id == id })!
                self.noteBook[i] = note
            })
    }
    
    func noteBinding(forIndex index: Int) -> Binding<Note> {
        .init(
            get: { () -> Note in
                self.noteBook[index]
            },
            set: { note in
                self.noteBook[index] = note
            })
    }
}


// MARK:- Sync with Cloud

extension DataStore: LocalStorage {
    
    func receiveDownload(from store: CloudStore, _ data: Data) {
        if let notebook = try? JSONDecoder().decode(NoteBook.self, from: data) {
            merge(cloudNotebook: notebook)
        }
    }
    
    func shouldUpload(to store: CloudStore) -> Bool {
        metadata.versionOfNotebookInCloud != noteBook.versionId
    }
    
    func dataToUpload(to store: CloudStore) throws -> Data {
        try JSONEncoder().encode(noteBook)
    }
    
}
