//
//  NoteBook.swift
//  Decent Notes
//
//  Created by Drew McCormack on 03/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import Foundation
import ReplicatingTypes

struct NoteBook: Replicable, Codable, Equatable {
    
    private var notesByIdentifier: ReplicatingDictionary<Note.ID, Note> {
        didSet {
            if notesByIdentifier != oldValue {
                changeVersion()
            }
        }
    }
    
    private var orderedNoteIdentifiers: ReplicatingArray<Note.ID> {
        didSet {
            if orderedNoteIdentifiers != oldValue {
                changeVersion()
            }
        }
    }
    
    private(set) var versionId: UUID = .init()
    private mutating func changeVersion() { versionId = UUID() }
    
    var notes: [Note] {
        orderedNoteIdentifiers.compactMap { notesByIdentifier[$0] }
    }
    
    init() {
        notesByIdentifier = .init()
        orderedNoteIdentifiers = .init()
    }
    
    subscript (_ index: Int) -> Note {
        get {
            let id = orderedNoteIdentifiers[index]
            return notesByIdentifier[id]!
        }
        set {
            let id = orderedNoteIdentifiers[index]
            notesByIdentifier[id] = newValue
        }
    }
    
    mutating func append(_ note: Note) {
        notesByIdentifier[note.id] = note
        orderedNoteIdentifiers.append(note.id)
    }
    
    mutating func remove(at index: Int) {
        let id = orderedNoteIdentifiers.remove(at: index)
        notesByIdentifier[id] = nil
    }
    
    mutating func moveNote(from source: Int, to destination: Int) {
        let id = orderedNoteIdentifiers[source]
        if source < destination {
            orderedNoteIdentifiers.insert(id, at: destination)
            orderedNoteIdentifiers.remove(at: source)
        } else {
            orderedNoteIdentifiers.remove(at: source)
            orderedNoteIdentifiers.insert(id, at: destination)
        }
    }
    
    func merged(with other: NoteBook) -> NoteBook {
        var new = self
        
        new.notesByIdentifier = notesByIdentifier.merged(with: other.notesByIdentifier)
        
        // Make sure there are no duplicates in the note identifiers.
        // Also confirm that a note exists for each identifier.
        // Begin by gathering the indices of the duplicates or invalid ids.
        let orderedIds = orderedNoteIdentifiers.merged(with: other.orderedNoteIdentifiers)
        var encounteredIds = Set<Note.ID>()
        var indicesForRemoval: [Int] = []
        for (i, id) in orderedIds.enumerated() {
            if !encounteredIds.insert(id).inserted || new.notesByIdentifier[id] == nil {
                indicesForRemoval.append(i)
            }
        }
        
        // Remove the non-unique entries in reverse order, so indices are valid
        var uniqueIds = orderedIds
        for i in indicesForRemoval.reversed() {
            uniqueIds.remove(at: i)
        }
        new.orderedNoteIdentifiers = uniqueIds
        
        return new
    }
}
