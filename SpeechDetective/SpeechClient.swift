//
//  SpeechClient.swift
//  SomeMoreTCA
//
//  Created by GWE48A on 11/14/22.
//

import ComposableArchitecture
import Combine
import Speech

struct SpeechClient {
  var finishTask: @Sendable () async -> Void
  var requestAuthorization: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
  var startTask:
  @Sendable (SFSpeechAudioBufferRecognitionRequest) async -> AsyncThrowingStream<
    SpeechRecognitionResult, Error
  >
  
  enum Failure: Error, Equatable {
    case taskError
    case couldntStartAudioEngine
    case couldntConfigureAudioSession
  }
}


extension SpeechClient {
  static var live: Self {
    let speech = Speech()
    
    return Self(
      finishTask: {
        await speech.finishTask()
      },
      requestAuthorization: {
        await withCheckedContinuation { continuation in
          SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status)
          }
        }
      },
      startTask: { request in
        let request = UncheckedSendable(request)
        return await speech.startTask(request: request)
      }
    )
  }
}

private actor Speech {
  var audioEngine: AVAudioEngine? = nil
  var recognitionTask: SFSpeechRecognitionTask? = nil
  var recognitionContinuation: AsyncThrowingStream<SpeechRecognitionResult, Error>.Continuation?
  
  func finishTask() {
    self.audioEngine?.stop()
    self.audioEngine?.inputNode.removeTap(onBus: 0)
    self.recognitionTask?.finish()
    self.recognitionContinuation?.finish()
  }
  
  func startTask(
    request: UncheckedSendable<SFSpeechAudioBufferRecognitionRequest>
  ) -> AsyncThrowingStream<SpeechRecognitionResult, Error> {
    let request = request.wrappedValue
    
    return AsyncThrowingStream { continuation in
      self.recognitionContinuation = continuation
      let audioSession = AVAudioSession.sharedInstance()
      do {
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .mixWithOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      } catch {
        continuation.finish(throwing: SpeechClient.Failure.couldntConfigureAudioSession)
        return
      }
      
      self.audioEngine = AVAudioEngine()
      let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
      self.recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
        switch (result, error) {
        case let (.some(result), _):
          continuation.yield(SpeechRecognitionResult(result))
        case (_, .some):
          continuation.finish(throwing: SpeechClient.Failure.taskError)
        case (.none, .none):
          fatalError("It should not be possible to have both a nil result and nil error.")
        }
      }
      
      continuation.onTermination = {
        [
          speechRecognizer = UncheckedSendable(speechRecognizer),
          audioEngine = UncheckedSendable(audioEngine),
          recognitionTask = UncheckedSendable(recognitionTask)
        ]
        _ in
        
        _ = speechRecognizer
        audioEngine.wrappedValue?.stop()
        audioEngine.wrappedValue?.inputNode.removeTap(onBus: 0)
        recognitionTask.wrappedValue?.finish()
      }
      
      self.audioEngine?.inputNode.installTap(
        onBus: 0,
        bufferSize: 1024,
        format: self.audioEngine?.inputNode.outputFormat(forBus: 0)
      ) { buffer, when in
        request.append(buffer)
      }
      
      self.audioEngine?.prepare()
      do {
        try self.audioEngine?.start()
      } catch {
        continuation.finish(throwing: SpeechClient.Failure.couldntStartAudioEngine)
        return
      }
    }
  }
}


// The core data types in the Speech framework are reference types and are not constructible by us,
// and so they aren't testable out the box. We define struct versions of those types to make
// them easier to use and test.

struct SpeechRecognitionMetadata: Equatable {
  var averagePauseDuration: TimeInterval
  var speakingRate: Double
  var voiceAnalytics: VoiceAnalytics?
}

struct SpeechRecognitionResult: Equatable {
  var bestTranscription: Transcription
  var isFinal: Bool
  var speechRecognitionMetadata: SpeechRecognitionMetadata?
  var transcriptions: [Transcription]
}

struct Transcription: Equatable {
  var formattedString: String
  var segments: [TranscriptionSegment]
}

struct TranscriptionSegment: Equatable {
  var alternativeSubstrings: [String]
  var confidence: Float
  var duration: TimeInterval
  var substring: String
  var timestamp: TimeInterval
}

struct VoiceAnalytics: Equatable {
  var jitter: AcousticFeature
  var pitch: AcousticFeature
  var shimmer: AcousticFeature
  var voicing: AcousticFeature
}

struct AcousticFeature: Equatable {
  var acousticFeatureValuePerFrame: [Double]
  var frameDuration: TimeInterval
}

extension SpeechRecognitionMetadata {
  init(_ speechRecognitionMetadata: SFSpeechRecognitionMetadata) {
    self.averagePauseDuration = speechRecognitionMetadata.averagePauseDuration
    self.speakingRate = speechRecognitionMetadata.speakingRate
    self.voiceAnalytics = speechRecognitionMetadata.voiceAnalytics.map(VoiceAnalytics.init)
  }
}

extension SpeechRecognitionResult {
  init(_ speechRecognitionResult: SFSpeechRecognitionResult) {
    self.bestTranscription = Transcription(speechRecognitionResult.bestTranscription)
    self.isFinal = speechRecognitionResult.isFinal
    self.speechRecognitionMetadata = speechRecognitionResult.speechRecognitionMetadata
      .map(SpeechRecognitionMetadata.init)
    self.transcriptions = speechRecognitionResult.transcriptions.map(Transcription.init)
  }
}

extension Transcription {
  init(_ transcription: SFTranscription) {
    self.formattedString = transcription.formattedString
    self.segments = transcription.segments.map(TranscriptionSegment.init)
  }
}

extension TranscriptionSegment {
  init(_ transcriptionSegment: SFTranscriptionSegment) {
    self.alternativeSubstrings = transcriptionSegment.alternativeSubstrings
    self.confidence = transcriptionSegment.confidence
    self.duration = transcriptionSegment.duration
    self.substring = transcriptionSegment.substring
    self.timestamp = transcriptionSegment.timestamp
  }
}

extension VoiceAnalytics {
  init(_ voiceAnalytics: SFVoiceAnalytics) {
    self.jitter = AcousticFeature(voiceAnalytics.jitter)
    self.pitch = AcousticFeature(voiceAnalytics.pitch)
    self.shimmer = AcousticFeature(voiceAnalytics.shimmer)
    self.voicing = AcousticFeature(voiceAnalytics.voicing)
  }
}

extension AcousticFeature {
  init(_ acousticFeature: SFAcousticFeature) {
    self.acousticFeatureValuePerFrame = acousticFeature.acousticFeatureValuePerFrame
    self.frameDuration = acousticFeature.frameDuration
  }
}


import XCTestDynamicOverlay

#if DEBUG
extension SpeechClient {
  static let unimplemented = Self(
    finishTask: XCTUnimplemented("\(Self.self).finishTask"),
    requestAuthorization: XCTUnimplemented(
      "\(Self.self).requestAuthorization", placeholder: .notDetermined
    ),
    startTask: XCTUnimplemented(
      "\(Self.self).recognitionTask", placeholder: AsyncThrowingStream.never
    )
  )
}
#endif

