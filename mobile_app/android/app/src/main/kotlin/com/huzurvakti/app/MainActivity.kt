package com.huzurvakti.app

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "huzur_glass_native",
            HuzurGlassNativeAdFactory(context)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "huzur_glass_native")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

class HuzurGlassNativeAdFactory(
    private val context: Context
) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_glass, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        val body = nativeAd.body
        if (body.isNullOrBlank()) {
            bodyView.visibility = View.GONE
        } else {
            bodyView.text = body
            bodyView.visibility = View.VISIBLE
        }
        adView.bodyView = bodyView

        val callToAction = nativeAd.callToAction
        if (callToAction.isNullOrBlank()) {
            ctaView.visibility = View.GONE
        } else {
            ctaView.text = callToAction
            ctaView.visibility = View.VISIBLE
        }
        adView.callToActionView = ctaView

        val icon = nativeAd.icon
        if (icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.setImageDrawable(icon.drawable)
            iconView.clipToOutline = true
            iconView.visibility = View.VISIBLE
        }
        adView.iconView = iconView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
