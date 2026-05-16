# Flutter / plugin entry points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class com.huzurvakti.app.MainActivity { *; }
-keep class com.huzurvakti.app.HuzurGlassNativeAdFactory { *; }
-keep class com.huzurvakti.app.HuzurPrayerWidget { *; }

# Google Mobile Ads / NativeAdFactory
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-keep public class * extends com.google.android.gms.ads.nativead.NativeAdView
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.gms.internal.ads.**

# Google Maps / Places / Location
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.libraries.places.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

# Firebase / Crashlytics / Analytics / Firestore
-keep class com.google.firebase.** { *; }
-keep class com.google.android.datatransport.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.protobuf.**

# RevenueCat / Billing / In-App Purchase
-keep class com.revenuecat.purchases.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.revenuecat.purchases.**
-dontwarn com.android.billingclient.**

# Alarm / notifications / background services
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.work.** { *; }
-dontwarn dev.fluttercommunity.plus.androidalarmmanager.**
-dontwarn com.dexterous.flutterlocalnotifications.**

# Media / audio / ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Gson / model reflection safety
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Kotlin metadata required by several Android libraries
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
