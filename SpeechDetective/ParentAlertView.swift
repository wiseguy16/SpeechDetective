// Copyright © 2022 AdventHealth. All rights reserved.

import SwiftUI
import ComposableArchitecture

struct BirthDater: ReducerProtocol {
  struct State: Equatable {
    var dateOnRecord: Date
    @BindableState var showAlert: Bool
    @BindableState var proceedToNext: Bool
    var hasMadeSelection = false
    var datesMatched = false
  }
  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case dismissAlert
    case shouldProceed
    case checkDateSelected(Date)
  }
  var body: some ReducerProtocol<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(_):
        return .none
      case .dismissAlert:
        state.showAlert.toggle()
        return .none
      case .shouldProceed:
        state.proceedToNext.toggle()
        state.showAlert = false
        return .none
      case let .checkDateSelected(selectedDate):
        state.hasMadeSelection.toggle()
        if Calendar.current.isDate(selectedDate, inSameDayAs: state.dateOnRecord) {
          state.datesMatched = true
          state.showAlert.toggle()
          state.proceedToNext.toggle()
        } else {
          state.datesMatched = false
        }
        return .none
      }
    }
  }

}

struct BirthDateAlertView: View {
  let store: StoreOf<BirthDater>
  
  @State private var selectedDate = Date()

  struct Constants {
    static let frameWidth = UIScreen.main.bounds.width * 0.92
    static let buttonHeight = UIScreen.main.bounds.height * 0.054
  }
        
      // MARK: - main body
  public var body: some View {
    WithViewStore(store) { viewStore in
      ZStack {
        Color(white: 0, opacity: 0.66).ignoresSafeArea()
        VStack {
          HStack {
            Text("Verify your date of Birth").font(.title3).bold()
              .foregroundColor(Color.black)
            Spacer()
            Button(action: {
              viewStore.send(.dismissAlert)
            }, label: {
              Image(systemName: "xmark").foregroundColor(Color.gray)
            })
          }
          .padding([.top, .leading, .trailing], 16)
          Divider()
          DatePicker("Enter your birthday", selection: $selectedDate, displayedComponents: [.date])
            .datePickerStyle(.graphical)
          HStack {
            Spacer()
            if viewStore.hasMadeSelection {
              Text(viewStore.datesMatched ? "Verified" : "Incorrect")
                .foregroundColor(viewStore.datesMatched ? .green : .red)
                .bold()
            }
            Button(action: {
              viewStore.send(.checkDateSelected(selectedDate))
            },
                   label: {
              Text("Submit")
                .padding([.leading, .trailing], 16)
                .frame(height: Constants.buttonHeight)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(4)
            })
          }
          .padding(16)
        }
        .frame(width: Constants.frameWidth)
        .background(Color.white)
        .cornerRadius(4)
        .padding([.leading, .trailing], 16)
      }
      .navigationBarHidden(viewStore.showAlert)
      .opacity(viewStore.showAlert ? 1 : 0)
      .animation(.default, value: viewStore.showAlert)
    }
  }
 
}



// MARK: - AlertModallyModifier
struct BirthDateAlertModifier: ViewModifier {
  var date: Date
  @Binding var showAlert: Bool
  @Binding var proceedToNext: Bool
  func body(content: Content) -> some View {
    ZStack {
      content
      BirthDateAlertView(store: .init(
              initialState: BirthDater.State(
                dateOnRecord: date, showAlert: showAlert, proceedToNext: proceedToNext),
              reducer: BirthDater()
            )
      )}
  }
}
extension View {
  public func validatingBirthDate(dateOnRecord: Date, isShowing: Binding<Bool>, proceedToNext: Binding<Bool>) -> some View {
    return modifier(BirthDateAlertModifier(date: dateOnRecord, showAlert: isShowing, proceedToNext: proceedToNext))
  }
}

struct RefillMedsView: View {
  let dateOnRecord: Date = mockAPIDateValue()
  @State var showBirthDateAlert = false
  @State var proceed = false
  
  var body: some View {
    NavigationView {
      VStack {
        Text("Your Medications").font(.title)
        Divider()
        HStack {
          Text("Magic Pills")
          Image(systemName: "pills.fill")
          Spacer()
          Button(action: {
            showBirthDateAlert.toggle()
          }, label: {
            Text("Refil Now")
          }).buttonStyle(.borderedProminent)
        }
        Spacer()
        NavigationLink(
          destination: PaymentMedsView(),
          isActive: $proceed) { EmptyView() }
        Divider()
        VStack(alignment: .leading, spacing: 12) {
          Text("(Cheat Section)").bold()
          Text("For date of birth, pick October 31, 2022")
          Button(action: {
            proceed.toggle()
          }, label: {
            Text("Destination Preview >")
          })
        }
      }
      .padding()
      .validatingBirthDate(dateOnRecord: dateOnRecord, isShowing: $showBirthDateAlert, proceedToNext: $proceed)
    }
  }
  
  static func mockAPIDateValue() -> Date {
    let dateOnRecordString = "2022-10-31"
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.date(from: dateOnRecordString) ?? Date()
  }
}

struct PaymentMedsView: View {

  var body: some View {
      VStack {
        Text("Payment for Meds").font(.title)
        Divider()
        HStack {
          Text("Magic Pills")
          Image(systemName: "pills.fill")
          Spacer()
          Text("Quantity: 30")
        }
        Button(action: {}, label: {
          Text("Pay Now")
        }).buttonStyle(.borderedProminent)
        Spacer()
      }
      .padding()
    }
  
}
              
     
// MARK: ----------------------------------------------------------


// MARK: ----------------------------------------------------------

struct ParentAlert: ReducerProtocol {
  
  struct State: Equatable {
    var title: String = ""
    var a = Int.random(in: 2...8)
    var b = Int.random(in: 2...8)
    var answerText = ""
    var answerIsCorrect = false
    var hasAnswered = false
//    var isShowingAlert: Bool = false
//    var shouldProceedToNext: Bool = false
    
    var cancelLabel: String
   
    var primaryLabel: String
    @BindableState var showAlert: Bool
    @BindableState var proceedToNext: Bool
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case numberTap(Int)
    case challenge(input: String)
    case submittedAnswer(correctly: Bool)
  }
  
  
//  func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
//    switch action {
  var body: some ReducerProtocol<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .numberTap(let num):
        state.answerText += String("\(num)")
        return .none
      case .challenge(let input):
        let answer = state.a * state.b
        let converted = Int(input) ?? 0
        state.hasAnswered = true
        
        if answer == converted {
          state.answerIsCorrect = true
          return Effect(value: .submittedAnswer(correctly: true))
            .delay(for: .seconds(0.7), scheduler: DispatchQueue.main)
            .eraseToEffect()
        } else {
          return Effect(value: .submittedAnswer(correctly: false))
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToEffect()
        }
        
      case .submittedAnswer(true):
        state.showAlert = false
        state.proceedToNext = true
        return .none
      case .submittedAnswer(false):
        state.showAlert = false
        state.proceedToNext = false
        state.answerText = ""
        state.answerIsCorrect = false
        state.hasAnswered = false
        return .none
//      case .proceedToNext:
//        return .none
      case .binding(\.$showAlert):
        return .none
      case .binding(\.$proceedToNext):
        return .none
//      case .binding(_):
//        return .none
      default:
        return .none
      }
    }._printChanges()
  }
}

// MARK: - ParentAlertViewTCA
public struct ParentAlertViewTCA: View {
 // @Binding var showAlert: Bool
  @Binding var proceedToNext: Bool
  
  let store: Store<ParentAlert.State, ParentAlert.Action>
  @ObservedObject var viewStore: ViewStore<ParentAlert.State, ParentAlert.Action>
  
  init(store: Store<ParentAlert.State, ParentAlert.Action>) {
    self.store = store
    self.viewStore = ViewStore(store)
    self._proceedToNext = ViewStore(store).binding(\.$proceedToNext)
  }
  

  
//  let title: String
//  let bodyMessage: String
//  let cancelAction: () -> Void
//  let cancelLabel: String
//  let primaryAction: () -> Void
//  let primaryLabel: String
//  @State var answerText = ""
//  @State var a = Int.random(in: 2...8)
//  @State var b = Int.random(in: 2...8)
//  @State var answerIsCorrect = false
//  @State var hasAnswered = false
  
  struct Constants {
    static let frameWidth = UIScreen.main.bounds.width * 0.92
    static let buttonHeight = UIScreen.main.bounds.height * 0.054
    static let titleSize = max(UIScreen.main.bounds.height * 0.0221, 19)
    static let descripSize = max(UIScreen.main.bounds.height * 0.02, 17)
    static let buttonTextSize = max(UIScreen.main.bounds.height * 0.018, 15)
  }
  
  // MARK: - main body
  public var body: some View {
    ZStack {
      Color(white: 0, opacity: 0.66)
        .ignoresSafeArea()
      bodyContainer
        .frame(width: Constants.frameWidth)
    }
    .navigationBarHidden(viewStore.showAlert)
    .opacity(viewStore.showAlert ? 1 : 0)
    .animation(.default, value: viewStore.showAlert)
    .onChange(of: viewStore.showAlert, perform: { showing in
//      if showing {
//        a = Int.random(in: 2...8)
//        b = Int.random(in: 3...7)
//      } else {
//        answerText = ""
//        answerIsCorrect = false
//        hasAnswered = false
//      }
     }
    )
    
  }
  
  // MARK: - bodyContainer
  var bodyContainer: some View {
    VStack {
      Spacer().frame(height: 24)
      top
      Divider()
      textBody
      Divider()
      answerArea
      numbersInput
      buttons
      Spacer().frame(height: 24)
    }
    .background(Color.white)
    .cornerRadius(4)
    .padding([.leading, .trailing], 16)
  }
  
  var answerArea: some View {
    VStack(spacing: 0) {
      Text("Answer: \(viewStore.answerText)").padding(4)
      if viewStore.hasAnswered {
        if viewStore.answerIsCorrect {
          Text("CORRECT!").padding(4)
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(4)
        } else {
          Text("Wrong").padding(4)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(4)
        }
      }
    }
  }
  
  /*
  func challenge(input: String) {
    let answer = a * b
    let convert = Int(input) ?? 0
    
    if answer == convert {
      answerIsCorrect = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
        showAlert.toggle()
        proceedToNext.toggle()
      }
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        showAlert.toggle()
      }
    }
    hasAnswered = true
  }
  */
  
  var numbersInput: some View {
    VStack {
      HStack {
        ForEach(0...4, id: \.self) { number in
          Button(action: {
            viewStore.send(.numberTap(number))
           // answerText += "\(number)"
            //impact(style: .rigid)
          }, label: {
            Text("\(number)").font(.title)
              .foregroundColor(.white)
              .padding()
              .background(Color.blue)
              .cornerRadius(8)
          })
          .buttonStyle(Thump(amount: .rigid))
        }
      }
      HStack {
        ForEach(5...9, id: \.self) { number in
          Button(action: {
            viewStore.send(.numberTap(number))
            //answerText += "\(number)"
            //impact(style: .rigid)
          }, label: {
            Text("\(number)").font(.title)
              .foregroundColor(.white)
              .padding()
              .background(Color.blue)
              .cornerRadius(8)
          }).buttonStyle(Thump(amount: .rigid))
        }
      }
    }
  }
  
  // MARK: - top
  var top: some View {
    HStack {
      Text(viewStore.title)
        .foregroundColor(Color.black)
     
      Spacer()
      Button(action: {
       // viewStore.send(.showAlert(proceed: false))
        //viewStore.showAlert.toggle()
        impact(style: .rigid)
      },
             label: {
        Image(systemName: "xmark")
          .foregroundColor(Color.gray)
      })
      .padding(.trailing, 8)
    }
    .padding([.leading, .trailing], 16)
  }
  
  // MARK: - textBody
  private var textBody: some View {
    Text("What is \(viewStore.a) x \(viewStore.b)?")
      .bold()
      .foregroundColor(Color.black)
      .lineSpacing(4)
      .fixedSize(horizontal: false, vertical: true)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
  }
  
  // MARK: - buttons
  private var buttons: some View {
    HStack(spacing: 12) {
      Spacer()
      Button(action: {
        //cancelAction()
        impact(style: .rigid)
      },
             label: {
        Text(viewStore.cancelLabel)
          .padding([.leading, .trailing], 16)
          .frame(height: Constants.buttonHeight)
          .foregroundColor(Color.blue)
      })
      .overlay(
        buttonOverlay
      )
      
      Button(action: {
        viewStore.send(.challenge(input: viewStore.answerText))
       // challenge(input: answerText)
       // primaryAction()
        impact(style: .rigid)
      },
             label: {
        Text(viewStore.primaryLabel)
          .padding([.leading, .trailing], 16)
          .frame(height: Constants.buttonHeight)
          .foregroundColor(.white)
          .background(Color.blue)
          .cornerRadius(4)
      })
    }
    .padding(.top, 16)
    .padding([.leading, .trailing], 16)
  }
  
  // MARK: - buttonOverlay
  private var buttonOverlay: some View {
    RoundedRectangle(cornerRadius: 4)
      .stroke(Color(.lightGray), lineWidth: 1.5)
      .frame(height: Constants.buttonHeight)
  }
  
  func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let imp = UIImpactFeedbackGenerator(style: style)
    imp.impactOccurred()
  }
}

// MARK: - AlertModallyModifier
struct ParentalAlertModifierTCA: ViewModifier {
  @Binding var showAlert: Bool
  @Binding var proceedToNext: Bool
  let title: String
  let bodyMessage: String
  let cancelAction: () -> Void
  let cancelLabel: String
  let primaryLabel: String
  
  func body(content: Content) -> some View {
    ZStack {
      content
      ParentAlertViewTCA(
        store:
          .init(
            initialState: ParentAlert.State(
              title: title,
   
              cancelLabel: cancelLabel,
              primaryLabel: primaryLabel,
              showAlert: showAlert,
              proceedToNext: proceedToNext
            ),
            reducer: ParentAlert()))
//      (
//        showAlert: $showAlert, proceedToNext: $proceedToNext,
//        title: title,
//        bodyMessage: bodyMessage,
//        cancelAction: cancelAction,
//        cancelLabel: cancelLabel,
//        primaryAction: primaryAction,
//        primaryLabel: primaryLabel)
    }
  }
}

extension View {
  
  // MARK: - Alert Modally
  /// Place this view modifier at the end of the main body of your view.
  /// This will embed your existing view in a ZStack and place the alert on top
  /// of everything else, with a dimming screen underneath the alert.
  ///
  /// This `modal` alert will be displayed in the center of the screen
  /// using our current CreationKit styling.
  public func parentalAlertTCA(isShowing: Binding<Bool>, proceedToNext: Binding<Bool>, title: String, bodyMessage: String, cancelAction: (() -> Void)? = nil, cancelLabel: String? = nil, primaryLabel: String) -> some View {
    
    let cancel = cancelAction ?? { isShowing.wrappedValue.toggle() }
    let cancelText = cancelLabel ?? "Cancel"
    
    return modifier(ParentalAlertModifierTCA(showAlert: isShowing, proceedToNext: proceedToNext, title: title, bodyMessage: bodyMessage, cancelAction: cancel, cancelLabel: cancelText, primaryLabel: primaryLabel))
  }
}


// MARK: - ParentAlertView
public struct ParentAlertView: View {
  @Binding var showAlert: Bool
  @Binding var proceedToNext: Bool
  let title: String
  let bodyMessage: String
  let cancelAction: () -> Void
  let cancelLabel: String
  //let primaryAction: () -> Void
  let primaryLabel: String
  @State var answerText = ""
  @State var a = Int.random(in: 2...8)
  @State var b = Int.random(in: 2...8)
  @State var answerIsCorrect = false
  @State var hasAnswered = false
  
  struct Constants {
    static let frameWidth = UIScreen.main.bounds.width * 0.92
    static let buttonHeight = UIScreen.main.bounds.height * 0.054
    static let titleSize = max(UIScreen.main.bounds.height * 0.0221, 19)
    static let descripSize = max(UIScreen.main.bounds.height * 0.02, 17)
    static let buttonTextSize = max(UIScreen.main.bounds.height * 0.018, 15)
  }
  
  // MARK: - main body
  public var body: some View {
    ZStack {
      Color(white: 0, opacity: 0.66)
        .ignoresSafeArea()
      bodyContainer
        .frame(width: Constants.frameWidth)
    }
    .navigationBarHidden(showAlert)
    .opacity(showAlert ? 1 : 0)
    .animation(.default, value: showAlert)
    .onChange(of: showAlert, perform: { showing in
      if showing {
        a = Int.random(in: 2...8)
        b = Int.random(in: 3...7)
      } else {
        answerText = ""
        answerIsCorrect = false
        hasAnswered = false
      }
    }
    )
    
  }
  
  // MARK: - bodyContainer
  var bodyContainer: some View {
    VStack {
      Spacer().frame(height: 24)
      top
      Divider()
      textBody
      Divider()
      answerArea
      numbersInput
      buttons
      Spacer().frame(height: 24)
    }
    .background(Color.white)
    .cornerRadius(4)
    .padding([.leading, .trailing], 16)
  }
  
  var answerArea: some View {
    VStack(spacing: 0) {
      Text("Answer: \(answerText)").padding(4)
      if hasAnswered {
        if answerIsCorrect {
          Text("CORRECT!").padding(4)
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(4)
        } else {
          Text("Wrong").padding(4)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(4)
        }
      }
    }
  }
  
  
  func challenge(input: String) {
    let answer = a * b
    let convert = Int(input) ?? 0
    
    if answer == convert {
      answerIsCorrect = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
        showAlert.toggle()
        proceedToNext.toggle()
      }
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        showAlert.toggle()
      }
    }
    hasAnswered = true
  }
   
  
  var numbersInput: some View {
    VStack {
      HStack {
        ForEach(0...4, id: \.self) { number in
          Button(action: {
            answerText += "\(number)"
            impact(style: .rigid)
          }, label: {
            Text("\(number)").font(.title)
              .foregroundColor(.white)
              .padding()
              .background(Color.blue)
              .cornerRadius(8)
          })
          .buttonStyle(Thump(amount: .rigid))
        }
      }
      HStack {
        ForEach(5...9, id: \.self) { number in
          Button(action: {
            answerText += "\(number)"
            impact(style: .rigid)
          }, label: {
            Text("\(number)").font(.title)
              .foregroundColor(.white)
              .padding()
              .background(Color.blue)
              .cornerRadius(8)
          }).buttonStyle(Thump(amount: .rigid))
        }
      }
    }
  }
  
  // MARK: - top
  var top: some View {
    HStack {
      Text(title)
        .foregroundColor(Color.black)
      
      Spacer()
      Button(action: {
        showAlert.toggle()
        impact(style: .rigid)
      },
             label: {
        Image(systemName: "xmark")
          .foregroundColor(Color.gray)
      })
      .padding(.trailing, 8)
    }
    .padding([.leading, .trailing], 16)
  }
  
  // MARK: - textBody
  private var textBody: some View {
    Text("What is \(a) x \(b)?")
      .bold()
      .foregroundColor(Color.black)
      .lineSpacing(4)
      .fixedSize(horizontal: false, vertical: true)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
  }
  
  // MARK: - buttons
  private var buttons: some View {
    HStack(spacing: 12) {
      Spacer()
      Button(action: {
        cancelAction()
        impact(style: .rigid)
      },
             label: {
        Text(cancelLabel)
          .padding([.leading, .trailing], 16)
          .frame(height: Constants.buttonHeight)
          .foregroundColor(Color.blue)
      })
      .overlay(
        buttonOverlay
      )
      
      Button(action: {
         challenge(input: answerText)
        // primaryAction()
        impact(style: .rigid)
      },
             label: {
        Text(primaryLabel)
          .padding([.leading, .trailing], 16)
          .frame(height: Constants.buttonHeight)
          .foregroundColor(.white)
          .background(Color.blue)
          .cornerRadius(4)
      })
    }
    .padding(.top, 16)
    .padding([.leading, .trailing], 16)
  }
  
  // MARK: - buttonOverlay
  private var buttonOverlay: some View {
    RoundedRectangle(cornerRadius: 4)
      .stroke(Color(.lightGray), lineWidth: 1.5)
      .frame(height: Constants.buttonHeight)
  }
  
  func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let imp = UIImpactFeedbackGenerator(style: style)
    imp.impactOccurred()
  }
}

// MARK: - AlertModallyModifier
struct ParentalAlertModifier: ViewModifier {
  @Binding var showAlert: Bool
  @Binding var proceedToNext: Bool
  let title: String
  let bodyMessage: String
  let cancelAction: () -> Void
  let cancelLabel: String
  let primaryLabel: String
  
  func body(content: Content) -> some View {
    ZStack {
      content
      ParentAlertView(
        showAlert: $showAlert,
        proceedToNext: $proceedToNext,
        title: title,
        bodyMessage: bodyMessage,
        cancelAction: cancelAction,
        cancelLabel: cancelLabel,
        primaryLabel: primaryLabel)
    }
  }
}

extension View {
  
  // MARK: - Alert Modally
  /// Place this view modifier at the end of the main body of your view.
  /// This will embed your existing view in a ZStack and place the alert on top
  /// of everything else, with a dimming screen underneath the alert.
  ///
  /// This `modal` alert will be displayed in the center of the screen
  /// using our current CreationKit styling.
  public func parentalAlert(isShowing: Binding<Bool>, proceedToNext: Binding<Bool>, title: String, bodyMessage: String, cancelAction: (() -> Void)? = nil, cancelLabel: String? = nil, primaryLabel: String) -> some View {
    
    let cancel = cancelAction ?? { isShowing.wrappedValue.toggle() }
    let cancelText = cancelLabel ?? "Cancel"
    
    return modifier(ParentalAlertModifier(showAlert: isShowing, proceedToNext: proceedToNext, title: title, bodyMessage: bodyMessage, cancelAction: cancel, cancelLabel: cancelText, primaryLabel: primaryLabel))
  }
}


