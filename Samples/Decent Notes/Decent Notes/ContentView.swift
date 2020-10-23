//
//  ContentView.swift
//  Decent Notes
//
//  Created by Drew McCormack on 03/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationView {
            NoteListView()
                .navigationBarTitle(Text("Notes"))
                .navigationBarItems(
                    leading: EditButton(),
                    trailing: Button(
                        action: {
                            withAnimation { self.dataStore.addNote() }
                        }
                    ) {
                        Image(systemName: "plus")
                    }
                )
            NoNoteView()
        }
    }
}
