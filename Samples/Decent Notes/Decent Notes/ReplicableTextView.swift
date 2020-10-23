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

struct ReplicatingTextView: UIViewRepresentable {
    @Binding var text: ReplicatingArray<Character>
    @State var selectedRange: NSRange = .init(location: NSNotFound, length: 0)
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.backgroundColor = UIColor(named: "textViewBackground")
        view.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)
        view.textContainerInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        return view
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.updatingUITextView = true
        
        let string = String(text.values)
        textView.text = string
        
        // Update the selection
        if selectedRange.location != NSNotFound, selectedRange.upperBound <= textView.textStorage.length {
            textView.selectedRange = selectedRange
        }
        
        context.coordinator.updatingUITextView = false
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var replicatingTextView: ReplicatingTextView
        
        fileprivate var updatingUITextView = false
        
        init(_ textView: ReplicatingTextView) {
            self.replicatingTextView = textView
        }
                
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText newText: String) -> Bool {
            // If we are populating the view with model data, let it go ahead, and return immediately
            guard !updatingUITextView else { return true }
            
            // If this is a user edit, don't make the change directly, but
            // instead update the model, which will trigger a view update
            for _ in 0..<range.length {
                replicatingTextView.text.remove(at: range.location)
            }
            
            for c in newText.reversed() {
                replicatingTextView.text.insert(c, at: range.location)
            }
            
            // Update selection. We don't update the text view selection directly,
            // but store the new value, which will be used in updateUIView.
            replicatingTextView.selectedRange.location = range.location + newText.count
            replicatingTextView.selectedRange.length = 0

            return false
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !updatingUITextView else { return }
            replicatingTextView.selectedRange = textView.selectedRange
        }
    }
}
