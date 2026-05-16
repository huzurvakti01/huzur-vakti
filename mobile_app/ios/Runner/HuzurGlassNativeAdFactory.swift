import Flutter
import GoogleMobileAds
import UIKit

final class HuzurGlassNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(
        _ nativeAd: NativeAd,
        customOptions: [AnyHashable : Any]? = nil
    ) -> NativeAdView {
        let adView = NativeAdView(frame: CGRect(x: 0, y: 0, width: 360, height: 124))

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(red: 0.07, green: 0.16, blue: 0.22, alpha: 0.92)
        container.layer.cornerRadius = 22
        container.layer.borderColor = UIColor(red: 0.85, green: 0.71, blue: 0.37, alpha: 0.25).cgColor
        container.layer.borderWidth = 1
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.18
        container.layer.shadowRadius = 18
        container.layer.shadowOffset = CGSize(width: 0, height: 10)

        adView.addSubview(container)

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFill
        icon.layer.cornerRadius = 14
        icon.clipsToBounds = true

        let badge = UILabel()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.text = "AD"
        badge.textColor = UIColor(red: 0.03, green: 0.07, blue: 0.12, alpha: 1)
        badge.font = .systemFont(ofSize: 10, weight: .heavy)
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(red: 0.85, green: 0.71, blue: 0.37, alpha: 1)
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true

        let headline = UILabel()
        headline.translatesAutoresizingMaskIntoConstraints = false
        headline.textColor = .white
        headline.font = .systemFont(ofSize: 16, weight: .bold)
        headline.numberOfLines = 1

        let body = UILabel()
        body.translatesAutoresizingMaskIntoConstraints = false
        body.textColor = UIColor.white.withAlphaComponent(0.78)
        body.font = .systemFont(ofSize: 13, weight: .medium)
        body.numberOfLines = 2

        let callToAction = UIButton(type: .system)
        callToAction.translatesAutoresizingMaskIntoConstraints = false
        callToAction.setTitleColor(UIColor(red: 0.03, green: 0.07, blue: 0.12, alpha: 1), for: .normal)
        callToAction.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        callToAction.backgroundColor = UIColor(red: 0.85, green: 0.71, blue: 0.37, alpha: 1)
        callToAction.layer.cornerRadius = 16
        callToAction.contentEdgeInsets = UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14)

        let textStack = UIStackView(arrangedSubviews: [badge, headline, body])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 5
        textStack.alignment = .leading

        let row = UIStackView(arrangedSubviews: [icon, textStack, callToAction])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        container.addSubview(row)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: adView.topAnchor),
            container.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

            icon.widthAnchor.constraint(equalToConstant: 54),
            icon.heightAnchor.constraint(equalToConstant: 54),

            callToAction.heightAnchor.constraint(equalToConstant: 44),
            callToAction.widthAnchor.constraint(greaterThanOrEqualToConstant: 92),

            badge.heightAnchor.constraint(equalToConstant: 20),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 32)
        ])

        headline.text = nativeAd.headline
        body.text = nativeAd.body
        callToAction.setTitle(nativeAd.callToAction, for: .normal)

        if let image = nativeAd.icon?.image {
            icon.image = image
            icon.isHidden = false
        } else {
            icon.isHidden = true
        }

        body.isHidden = nativeAd.body == nil
        callToAction.isHidden = nativeAd.callToAction == nil

        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = callToAction
        adView.iconView = icon
        adView.nativeAd = nativeAd

        return adView
    }
}
