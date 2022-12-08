// Copyright © 2022 AdventHealth. All rights reserved.

import SwiftUI
import ComposableArchitecture

// MARK: - ParentAlertView
public struct ParentAlertView: View {
  @Binding var showAlert: Bool
  @Binding var proceedToNext: Bool
  let title: String
  let bodyMessage: String
  let cancelAction: () -> Void
  let cancelLabel: String
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

  public func parentalAlert(isShowing: Binding<Bool>, proceedToNext: Binding<Bool>, title: String, bodyMessage: String, cancelAction: (() -> Void)? = nil, cancelLabel: String? = nil, primaryLabel: String) -> some View {
    
    let cancel = cancelAction ?? { isShowing.wrappedValue.toggle() }
    let cancelText = cancelLabel ?? "Cancel"
    
    return modifier(ParentalAlertModifier(showAlert: isShowing, proceedToNext: proceedToNext, title: title, bodyMessage: bodyMessage, cancelAction: cancel, cancelLabel: cancelText, primaryLabel: primaryLabel))
  }
}


