//
//  HomeViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import GoogleMobileAds

class HomeViewModel : OrbisViewModel {
    
    var homeTab: HomeTab?
    var prevHomeTab: HomeTab?
    var radarTab: RadarTab?
    
    override fileprivate init() { }
    
    private static var shared: HomeViewModel = {
        return HomeViewModel()
    }()

    // Workaround used when application is reload due language change
    static func recreate() {
        shared = HomeViewModel()
    }
    
    static func instance() -> HomeViewModel {
        return HomeViewModel.shared
    }

    let contentOffsetSubject = PublishSubject<(RadarTab, CGFloat)>()
    let tabSelectedSubject = PublishSubject<HomeTab>()
    let radarTabSelectedSubject = PublishSubject<RadarTab>()
    let updateRadarProgressBarSubject = PublishSubject<Bool>()
    let radarWillAppearSubject = PublishSubject<(RadarTab, CGFloat)>()
    let homeTopCardHeightReseted = PublishSubject<RadarTab>() // Value is the tab that trigered the reset
    let maximizeTopCardSubject = PublishSubject<Bool>()
    let minimizeTopCardSubject = PublishSubject<Bool>()
    let adMobLoadedSubject = PublishSubject<(RadarTab, GADUnifiedNativeAd)>()
    let moreAdMobsRequiredSubject = PublishSubject<Bool>()
    let defaultSubject = PublishSubject<Any>()
    
    func tabSelected(tab: HomeTab) {
        prevHomeTab = homeTab
        homeTab = tab
        tabSelectedSubject.onNext(tab)
    }

    func tabSelected(tab: RadarTab) {
        radarTab = tab
        radarTabSelectedSubject.onNext(tab)
    }
    
    func updateRadarProgressBar(isLoading: Bool) {
        updateRadarProgressBarSubject.onNext(isLoading)
    }
    
    func radarDidAppear(tab: RadarTab, contentOffset: CGFloat) {
        //contentOffsetSubject.onNext((tab, contentOffset))
    }
    
    func radarWillAppear(tab: RadarTab, contentOffset: CGFloat) {
        radarWillAppearSubject.onNext((tab, contentOffset))
    }
    
    func topCardHeightReseted(by radarTab: RadarTab) {
        homeTopCardHeightReseted.onNext(radarTab)
    }
    
    func onAdMobLoaded(ad: GADUnifiedNativeAd) {
        print2("[AdMob] [HomeViewModel] onAdMobLoaded")
        let tab = radarTab ?? RadarTab.myFeed
        adMobLoadedSubject.onNext((tab, ad))
    }
    
}
