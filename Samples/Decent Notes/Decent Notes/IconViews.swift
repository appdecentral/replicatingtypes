//
//  IconViews.swift
//  Decent Notes
//
//  Created by Drew McCormack on 01/06/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import SwiftUI

struct NoteIconView: View {
    var priority: Note.Priority
    
    var body: some View {
        ZStack {
            Image(systemName: "rectangle")
                .rotationEffect(.init(degrees: 90))
                .font(.system(size: 30, weight: .light))
            Image(systemName: "line.horizontal.3")
                .font(.system(size: 15, weight: .light))
                .offset(x: 0, y: -5.0)
            Image(systemName: "circle.fill")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .light))
                .offset(x: -10.0, y: -15.0)
            PriorityBadgeView(priority: priority)
                .offset(x: -10.0, y: -15.0)
        }
        .foregroundColor(.purple)
    }
    
}

struct PriorityBadgeView: View {
    var priority: Note.Priority
    var isSelected: Bool = false
        
    var priorityImage: some View {
        switch priority {
        case .low:
            return Image(systemName: "3.circle.fill")
        case .normal:
            return Image(systemName: "2.circle.fill")
        case .high:
            return Image(systemName: "1.circle.fill")
        }
    }
    
    var body: some View {
        ZStack {
            Image(systemName: "square.fill")
                .foregroundColor(Color(UIColor.systemBackground))
                .font(.system(size: 20, weight: .light))
            self.priorityImage
                .foregroundColor(.yellow)
                .font(.system(size: 20, weight: .light))
        }
        .offset(x: 0.0, y: self.isSelected ? -2.0 : 0.0)
        .transformEffect(self.isSelected ? .init(scaleX: 1.1, y: 1.1) : .identity)
    }
    
}
