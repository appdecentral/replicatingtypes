//
//  TagButtonViews.swift
//  Decent Notes
//
//  Created by Drew McCormack on 27/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import SwiftUI

struct ToggleButton: View {
    var label: String
    @Binding var isSelected: Bool
    var color: Color = .purple
    
    var body: some View {
        Button(
            action: {
                self.isSelected.toggle()
            },
            label: {
                HStack {
                    Text(label)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.caption)
                }
                .padding([.top, .bottom], 6)
                .padding([.leading, .trailing], 10)
            }
        )
        .foregroundColor(.white)
        .overlay(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 5.0)
                        .stroke(color.opacity(0.7), lineWidth: 4)
                } else {
                    EmptyView()
                }
            }
        )
        .background(
            RoundedRectangle(cornerRadius: 5.0)
                .fill(color)
                .brightness(-0.2)
        )
        .padding(.trailing, 5)
    }
    
}

struct RadioButtonList: View {
    var allLabels: [String]
    @Binding var selectedLabels: Set<String>
    
    func isSelectedBinding(label: String) -> Binding<Bool> {
        .init(
            get: {
                self.selectedLabels.contains(label)
            }, set: { isSelected in
                if isSelected {
                    self.selectedLabels.insert(label)
                } else {
                    self.selectedLabels.remove(label)
                }
            })
    }
    
    var body: some View {
        HStack {
            ForEach(allLabels.sorted(), id: \.self) { label in
                ToggleButton(label: label, isSelected: self.isSelectedBinding(label: label))
            }
        }
    }
}
