//
//  SpeechDetectiveApp.swift
//  SpeechDetective
//
//  Created by Gregory Weiss on 12/8/22.
//

import SwiftUI
import ComposableArchitecture

@main
struct SpeechDetectiveApp: App {
    var body: some Scene {
        WindowGroup {
          TopLevelView(
            store:
              Store(
                initialState:
                  TopLevel.State(todoState: TodoApp.State(),
                                 speechState: SpeechApp.State()
                ),
                reducer: TopLevel()
              )
          )
        }
    }
}
