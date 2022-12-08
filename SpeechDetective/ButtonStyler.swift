//
//  ButtonStyler.swift
//  SomeMoreTCA
//
//  Created by GWE48A on 11/18/22.
//

import SwiftUI

struct ImpactModifier: ViewModifier {
  let amount: UIImpactFeedbackGenerator.FeedbackStyle
  func body(content: Content) -> some View {
    content
      .buttonStyle(Thump(amount: amount))
  }
}

extension View {
  public func withImpact(amount: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
    return modifier(ImpactModifier(amount: amount))
  }
}

struct Thump: ButtonStyle {
  let amount: UIImpactFeedbackGenerator.FeedbackStyle
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .onChange(of: configuration.isPressed) { newValue in
        if newValue {
          impact(style: amount)
        }
      }
  }
  
  func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    print("Impacting!")
    let imp = UIImpactFeedbackGenerator(style: style)
    imp.impactOccurred()
  }

}

