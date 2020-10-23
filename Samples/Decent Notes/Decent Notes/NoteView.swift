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
                TextField("Title", text: $note.title.value)
                    .font(Font.headline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.purple)
                Spacer()
                PriorityButton(labelPriority: .high, notePriority: self.$note.priority.value)
                PriorityButton(labelPriority: .normal, notePriority: self.$note.priority.value)
                PriorityButton(labelPriority: .low, notePriority: self.$note.priority.value)
            }
            ReplicatingTextView(text: $note.text)
            RadioButtonList(
                allLabels: Note.Tag.allCases.map({ $0.rawValue }),
                selectedLabels: $note.tagStringSet
            )
            .padding(.top, 5.0)
            .padding(.bottom, 15.0)
            Text("Created on \(formattedCreationDate)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
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
