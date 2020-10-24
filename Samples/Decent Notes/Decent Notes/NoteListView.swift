//
//  NoteListView.swift
//  Decent Notes
//
//  Created by Drew McCormack on 05/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import SwiftUI
import ReplicatingTypes

struct NoteListView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        List {
            ForEach(dataStore.noteBook.notes) { note in
                NavigationLink(
                    destination: NoteView(note: self.dataStore.noteBinding(forId: note.id))
                ) {
                    HStack {
                        NoteIconView(priority: note.priority.value)
                        VStack(alignment: .leading) {
                            Text(note.displayedTitle)
                                .font(.headline)
                            Text(note.tagsString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                }
            }
            .onDelete { indices in
                indices.forEach { self.dataStore.deleteNote(at: $0) }
            }
            .onMove { sources, destination in
                dataStore.noteBook.moveNote(from: sources.first!, to: destination)
            }
        }
    }
}
