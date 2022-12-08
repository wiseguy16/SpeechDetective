//
//  Todo.swift
//  SomeMoreTCA
//
//  Created by GWE48A on 11/13/22.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct Todo: ReducerProtocol {
  
  struct State: Equatable, Identifiable, Codable {
    var description = ""
    let id: UUID
    var isComplete = false
  }
  
  enum Action: Equatable {
    case checkBoxToggled
    case textFieldChanged(String)
  }
  
  func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
    switch action {
    case .checkBoxToggled:
      state.isComplete.toggle()
      return .none
      
    case let .textFieldChanged(description):
      state.description = description
      return .none
    }
  }
}

struct TodoView: View {
  let store: StoreOf<Todo>
  
  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      HStack {
        Button(action: { viewStore.send(.checkBoxToggled) }) {
          Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
        }
        .buttonStyle(.plain)
        
        TextField(
          "Untitled Todo",
          text: viewStore.binding(get: \.description, send: Todo.Action.textFieldChanged)
        )
      }
      .foregroundColor(viewStore.isComplete ? .gray : nil)
    }
  }
}

enum Filter: LocalizedStringKey, CaseIterable, Hashable {
  case all = "All"
  case active = "Active"
  case completed = "Completed"
}

struct TodoApp: ReducerProtocol {
  struct State: Equatable {
    var editMode: EditMode = .inactive
    var filter: Filter = .all
    var todos: IdentifiedArrayOf<Todo.State> = []
    
    var filteredTodos: IdentifiedArrayOf<Todo.State> {
      switch filter {
      case .active: return self.todos.filter { !$0.isComplete }
      case .all: return self.todos
      case .completed: return self.todos.filter(\.isComplete)
      }
    }
  }
  
  enum Action: Equatable {
    case addTodoButtonTapped
    case clearCompletedButtonTapped
    case delete(IndexSet)
    case editModeChanged(EditMode)
    case filterPicked(Filter)
    case move(IndexSet, Int)
    case sortCompletedTodos
    case todo(id: Todo.State.ID, action: Todo.Action)
    case getAll
    case saveAll
  }
  
  var body: some ReducerProtocol<State, Action> {

    Reduce { state, action in
      switch action {
      case .addTodoButtonTapped:
        state.todos.insert(Todo.State(id: UUID()), at: 0)
        return .none
        
      case .clearCompletedButtonTapped:
        state.todos.removeAll(where: \.isComplete)
        return .none
        
      case let .delete(indexSet):
        state.todos.remove(atOffsets: indexSet)
        return .none
        
      case let .editModeChanged(editMode):
        state.editMode = editMode
        return .none
        
      case let .filterPicked(filter):
        state.filter = filter
        return .none
        
      case var .move(source, destination):
        if state.filter == .completed {
          source = IndexSet(
            source
              .map { state.filteredTodos[$0] }
              .compactMap { state.todos.index(id: $0.id) }
          )
          destination =
          (destination < state.filteredTodos.endIndex
           ? state.todos.index(id: state.filteredTodos[destination].id)
           : state.todos.endIndex)
          ?? destination
        }
        
        state.todos.move(fromOffsets: source, toOffset: destination)
        
        return .task {
          try await Task.sleep(nanoseconds: 1_000_000)
          return .sortCompletedTodos
        }
        
      case .sortCompletedTodos:
        state.todos.sort { $1.isComplete && !$0.isComplete }
        return .none
        
      case .todo(id: _, action: .checkBoxToggled):
        enum TodoCompletionID {}
        return .task {
          try await Task.sleep(nanoseconds: 1_000_000)
          return .sortCompletedTodos
        }
        .animation()
        .cancellable(id: TodoCompletionID.self, cancelInFlight: true)
        
      case .todo:
        return .none
      case .getAll:
        let allTodos = Filer.getSavedTodos()
        state.todos.append(contentsOf: allTodos)
        return .none
      case .saveAll:
        let currentTodos = state.todos.elements
        Filer.saveTodos(currentTodos)
        return .none
      }
    }
    .forEach(\.todos, action: /Action.todo) {
      Todo()
    }
  }
}

  
enum Filer {
  static func saveTodos(_ todos: [Todo.State]) {
    if let encodeData = try? JSONEncoder().encode(todos) {
      UserDefaults.standard.set(encodeData, forKey: "todoSaver")
    }
  }
  
  static func getSavedTodos() -> [Todo.State] {
    if let source = UserDefaults.standard.data(forKey: "todoSaver") {
      if let decodeData = try? JSONDecoder().decode([Todo.State].self, from: source) {
        return decodeData
      }
    }
    return []
  }
}



//struct AppEnvironment {
//  var mainQueue: AnySchedulerOf<DispatchQueue>
//  var uuid: @Sendable () -> UUID
//}
  
/*

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  todoReducer.forEach(
    state: \.todos,
    action: /AppAction.todo(id:action:),
    environment: { _ in TodoEnvironment() }
  ),
  Reducer { state, action, environment in
    switch action {
    case .addTodoButtonTapped:
      state.todos.insert(TodoState(id: environment.uuid()), at: 0)
      return .none
      
    case .clearCompletedButtonTapped:
      state.todos.removeAll(where: \.isComplete)
      return .none
      
    case let .delete(indexSet):
      state.todos.remove(atOffsets: indexSet)
      return .none
      
    case let .editModeChanged(editMode):
      state.editMode = editMode
      return .none
      
    case let .filterPicked(filter):
      state.filter = filter
      return .none
      
    case var .move(source, destination):
      if state.filter == .completed {
        source = IndexSet(
          source
            .map { state.filteredTodos[$0] }
            .compactMap { state.todos.index(id: $0.id) }
        )
        destination =
        (destination < state.filteredTodos.endIndex
         ? state.todos.index(id: state.filteredTodos[destination].id)
         : state.todos.endIndex)
        ?? destination
      }
      
      state.todos.move(fromOffsets: source, toOffset: destination)
      
      return .task {
        try await environment.mainQueue.sleep(for: .milliseconds(100))
        return .sortCompletedTodos
      }
      
    case .sortCompletedTodos:
      state.todos.sort { $1.isComplete && !$0.isComplete }
      return .none
      
    case .todo(id: _, action: .checkBoxToggled):
      enum TodoCompletionID {}
      return .task {
        try await environment.mainQueue.sleep(for: .seconds(1))
        return .sortCompletedTodos
      }
      .animation()
      .cancellable(id: TodoCompletionID.self, cancelInFlight: true)
      
    case .todo:
      return .none
    case .getAll:
      let allTodos = Filer.getSavedTodos()
      state.todos.append(contentsOf: allTodos)
      return .none
    case .saveAll:
      let currentTodos = state.todos.elements
      Filer.saveTodos(currentTodos)
      return .none
    }
  }
)

*/
  
  

struct TodoAppView: View {
  let store: StoreOf<TodoApp>
//  @ObservedObject var viewStore: ViewStore<ViewState, TodoApp.Action>

//  init(store: Store<TodoApp.State, TodoApp.Action>) {
//    self.store = store
//    self.viewStore = ViewStore(self.store.scope(state: ViewState.init(state:)))
//  }
//
//  struct ViewState: Equatable {
//    let editMode: EditMode
//    let filter: Filter
//    let isClearCompletedButtonDisabled: Bool
//
//    init(state: TodoApp.State) {
//      self.editMode = state.editMode
//      self.filter = state.filter
//      self.isClearCompletedButtonDisabled = !state.todos.contains(where: \.isComplete)
//    }
//  }
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        VStack(alignment: .leading) {
          Picker(
            "Filter",
            selection: viewStore.binding(get: \.filter, send: TodoApp.Action.filterPicked).animation()
          ) {
            ForEach(Filter.allCases, id: \.self) { filter in
              Text(filter.rawValue).tag(filter)
            }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)
          
          List {
            ForEachStore(
              self.store.scope(state: \.filteredTodos, action: TodoApp.Action.todo(id:action:))
            ) {
              TodoView(store: $0)
            }
            .onDelete { viewStore.send(.delete($0)) }
            .onMove { viewStore.send(.move($0, $1)) }
          }
          HStack {
            Button("Save Words") { viewStore.send(.saveAll) }.padding()
            Button("Get Words") { viewStore.send(.getAll) }.padding()
          }
        }
        
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            viewStore.send(.getAll)
          }
        }
        .navigationTitle("Todos")
        .navigationBarItems(
          trailing: HStack(spacing: 20) {
            EditButton()
            Button("Clear Completed") {
              viewStore.send(.clearCompletedButtonTapped, animation: .default)
            }
            //.disabled(viewStore.isClearCompletedButtonDisabled)
            Button("Add Todo") { viewStore.send(.addTodoButtonTapped, animation: .default) }
          }
        )
        .environment(
          \.editMode,
           viewStore.binding(get: \.editMode, send: TodoApp.Action.editModeChanged)
        )
      }
    }
    .navigationViewStyle(.stack)
  }
}


