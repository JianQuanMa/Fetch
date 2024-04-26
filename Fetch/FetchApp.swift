//
//  FetchApp.swift
//  Fetch
//
//  Created by Jian Ma on 4/25/24.
//

import SwiftUI

@main
struct FetcherciseApp: App {
    var body: some Scene {
        WindowGroup {
            MealsListView(
                viewModel: MealsListView.ViewModel(client: .live)
            )
        }
    }
}
