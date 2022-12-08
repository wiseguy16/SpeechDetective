//
//  TopLevelApp.swift
//  SomeMoreTCA
//
//  Created by GWE48A on 11/14/22.
//

import Combine
import ComposableArchitecture
import Speech
import Foundation
import SwiftUI
import AVFoundation
import AVKit

struct TopLevel: ReducerProtocol {
  
  struct State: Equatable {
    var word: String = "Hello"
    var index: Int = 0
    var currentWord: Todo.State?
    var todoState: TodoApp.State
    var speechState: SpeechApp.State
    var spokeCorrectly = false
  }
  
  enum Action: Equatable {
    case loadWords
    case getNextWord
    case evaluateSpeech
    case todos(TodoApp.Action)
    case speech(SpeechApp.Action)
  }
  
  var body: some ReducerProtocol<State, Action> {
    CombineReducers {
      Scope(state: \.todoState, action: /TopLevel.Action.todos) {
        TodoApp()
      }
      
      Scope(state: \.speechState, action: /TopLevel.Action.speech) {
        SpeechApp()
      }
      
      Reduce { state, action in
        switch action {
        case .getNextWord:
          state.spokeCorrectly = false
          if state.todoState.todos.count - 1 == state.index {
            state.index = 0
          } else {
            state.index += 1
          }
          state.currentWord = state.todoState.todos[state.index]
          let ref = state.currentWord?.description ?? ""
          return .run { send in
            await send(.speech(.setReference(ref: ref)))
          }
        case .loadWords:
          return .run { send in
            await send(.todos(.getAll))
          }
        case .evaluateSpeech:
          return .run { send in
            await send(.speech(.recordButtonTapped))
          }
        case .todos(_):
          return .none
        case .speech(.correctlySpoke):
          state.spokeCorrectly = true
          return .none
        default:
          return .none
        }
      }
      
    }._printChanges()
  }
  
}

protocol PathableProtocol: Codable, Hashable, Identifiable {
   var id: UUID { get }
}
extension PathableProtocol {
  var id: UUID {
    get {
      return UUID()
    }
  }
}
struct TodoPath: PathableProtocol {}
struct SpeechPath: PathableProtocol {}

struct TopLevelView: View {
  let store: Store<TopLevel.State, TopLevel.Action>
  @ObservedObject var viewStore: ViewStore<TopLevel.State, TopLevel.Action>
  
  init(store: Store<TopLevel.State, TopLevel.Action>) {
    self.store = store
    self.viewStore = ViewStore(store)
  }
  
  let todoDestination = TodoPath()
  let speechDestination = SpeechPath()
  @State private var shouldGotoTodos = false
  //@State private var path = NavigationPath()
  
  @State private var showListening = false
  @State private var showParentAlert = false
  
  let empty = { EmptyView() }

  var body: some View {
    NavigationView {
      VStack {
        // NavigationLink(value: todoDestination, label: empty)
        NavigationLink(
          destination: TodoAppView(
            store: self.store.scope(state: \.todoState, action: TopLevel.Action.todos)),
          isActive: $shouldGotoTodos,
          label: empty)
        
        VStack {
          menu
          sparkles
          wordToSpeak
          
          Spacer()
          
          micButton
          if showListening {
            listening
          }
          nextWordButton
        }
        
      }
      .navigationTitle("Speech Detective")
      .navigationBarTitleDisplayMode(.inline)
      .parentalAlert(isShowing: $showParentAlert, proceedToNext: $shouldGotoTodos, title: "Parents -", bodyMessage: "Provide answer:", primaryLabel: "Submit")
      .onChange(of: viewStore.spokeCorrectly) { correct in
        if correct {
          self.impactReward()
          AudioServicesPlaySystemSoundWithCompletion(1166, nil)
        }
        withAnimation(.easeInOut(duration: 0.3)) {
          self.showListening = false
        }
      }
      .onAppear {
        viewStore.send(.loadWords)
      }
    }
  }
  
  // MARK: - Sparkles
  var sparkles: some View {
    HStack {
      Image(systemName: "sparkles").foregroundColor(.yellow)
        .offset(x: viewStore.spokeCorrectly ? 0 : -15)
        .scaleEffect(viewStore.spokeCorrectly ? 1 : 0, anchor: .bottomLeading)
        .animation(.interpolatingSpring(stiffness: 170, damping: 8).delay(0.1), value: viewStore.spokeCorrectly)
      Image(systemName: "face.smiling").foregroundColor(.red)
        .offset(x: viewStore.spokeCorrectly ? 0 : -15)
        .scaleEffect(viewStore.spokeCorrectly ? 1 : 0, anchor: .bottom)
        .rotationEffect(.degrees(viewStore.spokeCorrectly ? 0 : -45))
        .animation(.interpolatingSpring(stiffness: 170, damping: 8).delay(0.2), value: viewStore.spokeCorrectly)
      Image(systemName: "sparkles").foregroundColor(.blue)
        .scaleEffect(viewStore.spokeCorrectly ? 1 : 0, anchor: .topTrailing)
        .rotationEffect(.degrees(viewStore.spokeCorrectly ? 0 : 45))
        .animation(.interpolatingSpring(stiffness: 170, damping: 8).delay(0.3), value: viewStore.spokeCorrectly)
    }
    .font(.largeTitle.bold())
    .opacity(viewStore.spokeCorrectly ? 1 : 0)
    .padding(.bottom, 40)
  }
 
  // MARK: - Menu
  var menu: some View {
      HStack {
        Spacer()
        Button(
          action: {
            showParentAlert.toggle()
            impact(style: .rigid)
          },
          label: {
            Image(systemName: "list.bullet.rectangle")
              .font(.largeTitle)
          }
        )
      }
      .padding(.horizontal)
      .padding(.bottom, 40)
  }
  

  
  // MARK: - WordToSpeak
  var wordToSpeak: some View {
    ZStack {
      LinearGradient(gradient: Gradient(colors: [.yellow, .mint, .red, .orange]), startPoint: .bottomLeading, endPoint: .topTrailing)
        .frame(width: 300, height: 250)
        .cornerRadius(20)
      
      Text(viewStore.currentWord?.description == nil ? "???" : "\(viewStore.currentWord?.description ?? "")")
        .font(.largeTitle.bold())
        .padding()
        .frame(width: 300, height: 250)
        .background(.thinMaterial)
        .cornerRadius(20)
    }
  }
  
  // MARK: - MicButton
  var micButton: some View {
    Button(
      action: {
        viewStore.send(.evaluateSpeech)
        impact(style: .rigid)
        withAnimation(.easeInOut(duration: 0.5)) {
          self.showListening = true
        }
      },
      label: {
        HStack {
          Image(
            systemName: viewStore.speechState.isRecording ? "mic.slash.fill" : "mic.fill")
          .font(.largeTitle)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
        .background(viewStore.speechState.isRecording ? Color.red : .green)
        .cornerRadius(16)
      }
    )
    
  }
  
  // MARK: - NextWordButton
  var nextWordButton: some View {
      HStack {
        Spacer()
        Button(
          action: {
            viewStore.send(.getNextWord)
            impact(style: .light)
          },
          label: {
            Image(systemName: "arrow.right.square")
              .resizable()
              .frame(width: 50, height: 40)
          }
        )
      }
      .padding()
  }
  
  var listening: some View {
    Image(systemName: "ear.and.waveform")
      .font(.largeTitle)
      .transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .slide), removal: .scale))
  }
  
  func impactReward() {
    impact(style: .rigid)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      impact(style: .rigid)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        impact(style: .rigid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          impact(style: .rigid)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact(style: .rigid)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              impact(style: .rigid)
            }
          }
        }
      }
    }
  }
  
  func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let imp = UIImpactFeedbackGenerator(style: style)
    imp.impactOccurred()
  }
  

  
}
