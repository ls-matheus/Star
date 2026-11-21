import CallKit
import Flutter

final class SystemVoiceCallGuard: SystemVoiceCallGuardHostApi {
  private let observer = CXCallObserver()

  func isExternalCallActive(
    starOwnsVoice: Bool,
    completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    if starOwnsVoice {
      completion(.success(false))
      return
    }
    completion(.success(observer.calls.contains { !$0.hasEnded }))
  }
}
