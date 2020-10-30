//
//  NoteView.swift
//  Decent Notes
//
//  Created by Drew McCormack on 05/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import SwiftUI

struct NoteView: View {
    @Binding var note: Note
    
    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: note.creationDate)
    }
    
    var body: some View {
        Group {
            HStack {
                TextField("Tap to add title", text: $note.title.value)
                    .font(Font.headline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.purple)
                Spacer()
                PriorityButton(labelPriority: .high, notePriority: $note.priority.value)
                PriorityButton(labelPriority: .normal, notePriority: $note.priority.value)
                PriorityButton(labelPriority: .low, notePriority: $note.priority.value)
            }
            ReplicatingCharactersView(replicatingCharacters: $note.text)
            RadioButtonList(
                allLabels: Note.Tag.allCases.map({ $0.rawValue }),
                selectedLabels: $note.tagStringSet
            )
            .padding(.top, 5.0)
            .padding(.bottom, 15.0)
            Text("Created on \(formattedCreationDate)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("A Decent Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PriorityButton: View {
    var labelPriority: Note.Priority
    @Binding var notePriority: Note.Priority
    
    var body: some View {
        Button(
            action: {
                self.notePriority = self.labelPriority
            },
            label: {
                PriorityBadgeView(priority: self.labelPriority, isSelected: self.notePriority == self.labelPriority)
            }
        )
    }
    
}

struct NoNoteView: View {
    var body: some View {
        Group {
            Text("Select a Note")
        }.navigationBarTitle(Text("No Selection"))
    }
}
