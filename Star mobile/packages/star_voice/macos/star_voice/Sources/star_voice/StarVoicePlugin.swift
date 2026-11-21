import FlutterMacOS
import Foundation

public final class StarVoicePlugin: NSObject, FlutterPlugin, VoiceProcessActivityHostApi {
  private var activity: NSObjectProtocol?

  public static func register(with registrar: FlutterPluginRegistrar) {
    VoiceProcessActivityHostApiSetup.setUp(
      binaryMessenger: registrar.messenger,
      api: StarVoicePlugin()
    )
  }

  func begin() throws {
    guard activity == nil else {
      return
    }
    activity = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
      reason: "Voice call in progress"
    )
  }

  func end() throws {
    guard let activity else {
      return
    }
    ProcessInfo.processInfo.endActivity(activity)
    self.activity = nil
  }
}
