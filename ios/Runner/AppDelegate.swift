import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The Google Maps key lives in the app's .env (GOOGLE_MAPS_API_KEY);
    // Dart sends it here at start-up, before any map is shown.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ApexMapsKey")
    else { return }
    let channel = FlutterMethodChannel(
      name: "apex/maps", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "setApiKey", let key = call.arguments as? String, !key.isEmpty
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      GMSServices.provideAPIKey(key)
      result(nil)
    }
  }
}
