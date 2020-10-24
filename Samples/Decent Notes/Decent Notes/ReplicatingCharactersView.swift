//
//  ReplicatingTextView.swift
//  Local Agenda
//
//  Created by Drew McCormack on 21/06/2019.
//  Copyright © 2019 Momenta B.V. All rights reserved.
//

import Foundation
import SwiftUI
import ReplicatingTypes

struct ReplicatingCharactersView: View {
    @Binding var replicatingCharacters: ReplicatingArray<Character>
    private var modelText: String { String(replicatingCharacters.values) }

    @State private var displayedText: String = ""
    
    var body: some View {
        TextEditor(text: $displayedText)
            .border(Color(white: 0.9))
            .onAppear {
                updateDisplayedTextWithModel()
            }
            .onChange(of: replicatingCharacters) { _ in
                updateDisplayedTextWithModel()
            }
            .onChange(of: displayedText) { _ in
                updateModelFromDisplayedText()
            }
    }
    
    private func updateDisplayedTextWithModel() {
        let modelText = self.modelText
        guard displayedText != modelText else { return }
        displayedText = modelText
    }
    
    private func updateModelFromDisplayedText() {
        guard displayedText != modelText else { return }
        let diff = displayedText.difference(from: modelText)
        var newChars = replicatingCharacters
        for d in diff {
            switch d {
            case let .insert(offset, element, _):
                newChars.insert(element, at: offset)
            case let .remove(offset, _, _):
                newChars.remove(at: offset)
            }
        }
        replicatingCharacters = newChars
    }
}
