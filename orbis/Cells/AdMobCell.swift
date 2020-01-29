//
//  AdMobCell.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 10/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import GoogleMobileAds

class AdMobCell : UITableViewCell {
    
    @IBOutlet weak var adView: GADUnifiedNativeAdView!

    func fill(adMob: GADUnifiedNativeAd) {
        adView.nativeAd = adMob
        
        (adView.headlineView as? UILabel)?.text = adMob.headline
        (adView.priceView as? UILabel)?.text = adMob.price
        (adView.bodyView as? UILabel)?.text = adMob.body
        (adView.advertiserView as? UILabel)?.text = adMob.advertiser
        (adView.callToActionView as? UIButton)?.isUserInteractionEnabled = false
        (adView.callToActionView as? UIButton)?.setTitle(adMob.callToAction?.uppercased(), for: .normal)
        (adView.iconView as? UIImageView)?.image = adMob.icon?.image
        (adView.priceView as? UILabel)?.text = adMob.price
        (adView.storeView as? UILabel)?.text = adMob.store
        (adView.mediaView)?.mediaContent = adMob.mediaContent
        
        if let starRating = adMob.starRating {
            (adView.starRatingView as? UILabel)?.text = starRating.description + "\u{2605}"
        } else {
            (adView.starRatingView as? UILabel)?.text = nil
        }
    }
    
}
