//
//  Note.swift
//  Decent Notes
//
//  Created by Drew McCormack on 03/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import Foundation
import ReplicatingTypes

struct Note: Identifiable, Replicable, Codable, Equatable {
    
    enum Priority: Int, Codable {
        case low, normal, high
    }
    
    enum Tag: String, Codable, CaseIterable {
        case home, work, travel, leisure
    }
    
    var id: UUID = .init()
    var title: ReplicatingRegister<String> = .init("A Decent Note")
    var text: ReplicatingArray<Character> = .init()
    var tags: ReplicatingSet<Tag> = .init()
    var priority: ReplicatingRegister<Priority> = .init(.normal)
    var creationDate: Date = .init()
    
    var tagsString: String {
        tags.values.map{ $0.rawValue }.sorted().joined(separator: ", ")
    }
    
    var tagStringSet: Set<String> {
        get {
            Set(tags.values.map({ $0.rawValue }))
        }
        set {
            tags.values.forEach { tags.remove($0) }
            newValue.forEach { tagString in
                if let tag = Tag(rawValue: tagString) {
                    tags.insert(tag)
                }
            }
        }
    }

    func merged(with other: Note) -> Note {
        assert(id == other.id)
        var newNote = self
        newNote.title = title.merged(with: other.title)
        newNote.text = text.merged(with: other.text)
        newNote.tags = tags.merged(with: other.tags)
        newNote.priority = priority.merged(with: other.priority)
        return newNote
    }
}

extension Character: Codable {
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let string = try container.decode(String.self)
        self = string.first!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(String(self))
    }
    
}
