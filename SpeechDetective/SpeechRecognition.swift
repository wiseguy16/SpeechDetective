//
//  SpeechRecognition.swift
//  SomeMoreTCA
//
//  Created by GWE48A on 11/14/22.
//

import Combine
import ComposableArchitecture
import Speech
import Foundation
@preconcurrency import SwiftUI

private enum SpeechClientKey: DependencyKey {
  static let liveValue = SpeechClient.live
}

extension DependencyValues {
  var speechClient: SpeechClient {
    get { self[SpeechClientKey.self] }
    set { self[SpeechClientKey.self] = newValue }
  }
}


private let readMe = """
  This application demonstrates how to work with a complex dependency in the Composable \
  Architecture. It uses the `SFSpeechRecognizer` API from the Speech framework to listen to audio \
  on the device and live-transcribe it to the UI.
  """
struct SpeechApp: ReducerProtocol {
  
  struct State: Equatable {
    var alert: AlertState<Action>?
    var isRecording = false
    var transcribedText = ""
    var referenceWord = ""
  }
  
  enum Action: Equatable {
    case authorizationStateAlertDismissed
    case recordButtonTapped
    case speech(TaskResult<String>)
    case speechRecognizerAuthorizationStatusResponse(SFSpeechRecognizerAuthorizationStatus)
    case checkSpeech(reference: String)
    case setReference(ref: String)
    case correctlySpoke
  }
  
  func checkWord(wordsSpoken: String, wordReference: String) -> Bool {
    if wordsSpoken.lowercased().contains(wordReference.lowercased()) { print("-----------\nYeah, you said \(wordReference)!\n------------")
      return true
    }
    return false
  }
  
  @Dependency(\.speechClient) var speechClient
  
  func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
    switch action {
    case .authorizationStateAlertDismissed:
      state.alert = nil
      return .none
      
    case .recordButtonTapped:
      state.isRecording.toggle()
      
      guard state.isRecording
      else {
        return .fireAndForget {
          await speechClient.finishTask()
        }
      }
      
      return .run { send in
        let status = await speechClient.requestAuthorization()
        await send(.speechRecognizerAuthorizationStatusResponse(status))
        
        guard status == .authorized
        else { return }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        for try await result in await speechClient.startTask(request) {
          await send(.speech(.success(result.bestTranscription.formattedString)), animation: .linear)
        }
      } catch: { error, send in
        await send(.speech(.failure(error)))
      }
      
    case .speech(.failure(SpeechClient.Failure.couldntConfigureAudioSession)),
        .speech(.failure(SpeechClient.Failure.couldntStartAudioEngine)):
      state.alert = AlertState(title: TextState("Problem with audio device. Please try again."))
      return .none
      
    case .speech(.failure):
      state.alert = AlertState(
        title: TextState("An error occurred while transcribing. Please try again.")
      )
      return .none
      
    case let .speech(.success(transcribedText)):
      state.transcribedText = transcribedText
      let ref = state.referenceWord
      
      return .run { send in
        await send(.checkSpeech(reference: ref))
      }
      
    case let .speechRecognizerAuthorizationStatusResponse(status):
      switch status {
      case .authorized:
        return .none
        
      case .denied:
        state.isRecording = false
        state.alert = AlertState(
          title: TextState(
          """
          You denied access to speech recognition. This app needs access to transcribe your speech.
          """
          )
        )
        return .none
        
      case .notDetermined:
        state.isRecording = false
        return .none
        
      case .restricted:
        state.isRecording = false
        state.alert = AlertState(title: TextState("Your device does not allow speech recognition."))
        return .none
        
      @unknown default:
        state.isRecording = false
        return .none
      }
    case .checkSpeech(reference: let reference):
      if checkWord(wordsSpoken: state.transcribedText, wordReference: reference) {
        return .run { send in
          await send(.recordButtonTapped)
          await send(.correctlySpoke)
        }
      }
      return .none
    case .setReference(ref: let ref):
      state.referenceWord = ref
      return .none
    case .correctlySpoke:
      return .none
    }
  }
}


struct SpeechAppView: View {
  let store: StoreOf<SpeechApp>
  
  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        VStack(alignment: .leading) {
          Text(readMe)
            .padding(.bottom, 32)
          
          Text(viewStore.transcribedText)
            .font(.largeTitle)
            .minimumScaleFactor(0.1)
            .frame(minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
        
        Spacer()
        
        Button(action: { viewStore.send(.recordButtonTapped) }) {
          HStack {
            Image(
              systemName: viewStore.isRecording
              ? "stop.circle.fill" : "arrowtriangle.right.circle.fill"
            )
            .font(.title)
            Text(viewStore.isRecording ? "Stop Recording" : "Start Recording")
          }
          .foregroundColor(.white)
          .padding()
          .background(viewStore.isRecording ? Color.red : .green)
          .cornerRadius(16)
        }
      }
      .padding()
      .alert(self.store.scope(state: \.alert), dismiss: .authorizationStateAlertDismissed)
    }
  }
}

struct SpeechAppView_Previews: PreviewProvider {
  static var previews: some View {
    SpeechAppView(
      store: Store(
        initialState: SpeechApp.State(transcribedText: "Test test 123"),
        reducer: SpeechApp()
      )
    )
  }
}

extension SpeechClient {
  static var lorem: Self {
    let isRecording = ActorIsolated(false)
    
    return Self(
      finishTask: { await isRecording.setValue(false) },
      requestAuthorization: { .authorized },
      startTask: { _ in
          .init { c in
            Task {
              await isRecording.setValue(true)
              var finalText = """
              Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor \
              incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud \
              exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute \
              irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla \
              pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui \
              officia deserunt mollit anim id est laborum.
              """
              var text = ""
              while await isRecording.value {
                let word = finalText.prefix { $0 != " " }
                try await Task.sleep(
                  nanoseconds: UInt64(word.count) * NSEC_PER_MSEC * 50
                  + .random(in: 0...(NSEC_PER_MSEC * 200))
                )
                finalText.removeFirst(word.count)
                if finalText.first == " " {
                  finalText.removeFirst()
                }
                text += word + " "
                c.yield(
                  .init(
                    bestTranscription: .init(
                      formattedString: text,
                      segments: []
                    ),
                    isFinal: false,
                    transcriptions: []
                  )
                )
              }
            }
          }
      }
    )
  }
}
  
  
  
  
  
  /*
   
   let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
   switch action {
   case .authorizationStateAlertDismissed:
   state.alert = nil
   return .none
   
   case .recordButtonTapped:
   state.isRecording.toggle()
   
   guard state.isRecording
   else {
   return .fireAndForget {
   await environment.speechClient.finishTask()
   }
   }
   
   return .run { send in
   let status = await environment.speechClient.requestAuthorization()
   await send(.speechRecognizerAuthorizationStatusResponse(status))
   
   guard status == .authorized
   else { return }
   
   let request = SFSpeechAudioBufferRecognitionRequest()
   for try await result in await environment.speechClient.startTask(request) {
   await send(.speech(.success(result.bestTranscription.formattedString)), animation: .linear)
   }
   } catch: { error, send in
   await send(.speech(.failure(error)))
   }
   
   case .speech(.failure(SpeechClient.Failure.couldntConfigureAudioSession)),
   .speech(.failure(SpeechClient.Failure.couldntStartAudioEngine)):
   state.alert = AlertState(title: TextState("Problem with audio device. Please try again."))
   return .none
   
   case .speech(.failure):
   state.alert = AlertState(
   title: TextState("An error occurred while transcribing. Please try again.")
   )
   return .none
   
   case let .speech(.success(transcribedText)):
   state.transcribedText = transcribedText
   checkWord(transcribedText)
   return .none
   
   case let .speechRecognizerAuthorizationStatusResponse(status):
   switch status {
   case .authorized:
   return .none
   
   case .denied:
   state.isRecording = false
   state.alert = AlertState(
   title: TextState(
   """
   You denied access to speech recognition. This app needs access to transcribe your speech.
   """
   )
   )
   return .none
   
   case .notDetermined:
   state.isRecording = false
   return .none
   
   case .restricted:
   state.isRecording = false
   state.alert = AlertState(title: TextState("Your device does not allow speech recognition."))
   return .none
   
   @unknown default:
   state.isRecording = false
   return .none
   }
   }
   
   func checkWord(_ word: String) {
   if word.lowercased().contains("dog") {
   print("yeah, you said dog!")
   }
   }
   }
   
   */


    
//    struct AppEnvironment {
//      var speechClient: SpeechClient
//      }
