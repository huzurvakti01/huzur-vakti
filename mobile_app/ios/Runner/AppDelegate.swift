import Flutter
import GoogleMobileAds
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var nativeAdFactory: HuzurGlassNativeAdFactory?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let factory = HuzurGlassNativeAdFactory()
    nativeAdFactory = factory
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "huzur_glass_native",
      nativeAdFactory: factory
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
