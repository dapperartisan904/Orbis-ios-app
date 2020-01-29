//
//  HomeViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import GoogleMobileAds
import Photos
import Crashlytics

enum HomeTab {
    case radar, map, groups
    
    func index() -> Int {
        switch self {
            case .radar: return 0
            case .map: return 1
            case .groups: return 2
        }
    }
    
}

class HomeViewController : OrbisViewController {

    @IBOutlet weak var topCardView: CardView!
    @IBOutlet weak var bottomCardView: CardView!
    @IBOutlet weak var tabRadarButton: UIButton!
    @IBOutlet weak var tabMapButton: UIButton!
    @IBOutlet weak var tabGroupsButton: UIButton!
    @IBOutlet weak var notRegisteredViewsContainer: UIView!
    @IBOutlet weak var registeredViewsWithoutGroupContainer: UIView!
    @IBOutlet weak var registeredViewsWithGroupContainer: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameLabel2: UILabel!
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var chooseGroupLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var topCardHeightConstraint: NSLayoutConstraint!
    
    private let homeViewModel = HomeViewModel.instance()
    private let likesViewModel = LikesViewModel.instance()
    private let rolesViewModel = RolesViewModel.instance()
    private let bannedUsersViewModel = BannedUsersViewModel.instance()
    private let registerViewModel = RegisterViewModel()
    private let placesViewModel = PlacesViewModel()
    
    private var locationManager: CLLocationManager!

    private var tutorialView: TutorialView?
    private var topCardDefHeight: CGFloat!
    private let topCardMinHeight: CGFloat = 70
    private let topCardHeightAnimDuration = 0.35
    private var radarOffset: [RadarTab : CGFloat] = [.myFeed : 0, .distanceFeed : 0]
   
    var tabToShow: HomeTab?
    
    private var adLoader: GADAdLoader?
    
    deinit {
        print2("[Lifecycle] [HomeViewController] deinit \(hashValue)")
    }
    
   
    
    override init(nibName: String?, bundle: Bundle?)
    {
        
        super.init(nibName: nibName, bundle: bundle)
        
        print2("[Lifecycle] [HomeViewController] init \(hashValue)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print2("[Lifecycle] [HomeViewController] init \(hashValue)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print2("[Lifecycle] [HomeViewController] viewDidLoad \(hashValue)")
        let mapIcon = UIImage(named: isProduction() ? "tab_map_active" : "baseline_bug_report_black_48pt")
        
        makeNavigationBarTransparent()
    
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        topCardDefHeight = topCardHeightConstraint.constant
        tabRadarButton.setImage(UIImage(named: "tab_radar_inactive"), for: .normal)
        tabRadarButton.setImage(UIImage(named: "tab_radar_active"), for: .selected)
        tabMapButton.setImage(UIImage(named: "tab_map_inactive"), for: .normal)
        tabMapButton.setImage(mapIcon, for: .selected)
        tabGroupsButton.setImage(UIImage(named: "tab_groups_inactive"), for: .normal)
        tabGroupsButton.setImage(UIImage(named: "tab_groups_active"), for: .selected)
        tabRadarButton.imageView?.contentMode = .scaleAspectFit
        tabMapButton.imageView?.contentMode = .scaleAspectFit
        tabGroupsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.imageView?.contentMode = .scaleAspectFit
        
        loginButton.setTitle(Words.login.localized, for: .normal)
        registerButton.setTitle(Words.register.localized, for: .normal)
        chooseGroupLabel.text = Words.chooseGroup.localized
        
        stackView.tabsStackView()
        
        observeDefaultSubject(subject: homeViewModel.defaultSubject)

        tabRadarButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .radar)
            }
            .disposed(by: bag)
        
        tabMapButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .map)
            }
            .disposed(by: bag)

        tabGroupsButton.rx.tap
            .bind { [weak self] in
                self?.selectTab(tab: .groups)
            }
            .disposed(by: bag)
        
        settingsButton.rx.tap
            .bind { [weak self] in
                self?.showViewController(withInfo: ViewControllerInfo.settings)
            }
            .disposed(by: bag)
        
        loginButton.rx.tap
            .bind { [weak self] in
                self?.showViewController(withInfo: ViewControllerInfo.login)
            }
            .disposed(by: bag)
        
        registerButton.rx.tap
            .bind { [weak self] in
                self?.showViewController(withInfo: ViewControllerInfo.register)
            }
            .disposed(by: bag)
        
        [usernameLabel, usernameLabel2].forEach { view in
            view.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    guard
                        let this = self,
                        let user = UserDefaultsRepository.instance().getMyUser()
                    else {
                        return
                    }
                    
                    this.handleNavigation(navigation: Navigation.user(user: user))
                })
                .disposed(by: bag)
        }
        
        [groupImageView, groupNameLabel].forEach { view in
            view.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    guard
                        let this = self,
                        let group = UserDefaultsRepository.instance().getActiveGroup()
                    else {
                        return
                    }
                    
                    this.handleNavigation(navigation: Navigation.group(group: group))
                })
                .disposed(by: bag)
        }
        
        homeViewModel.contentOffsetSubject
            .subscribe(onNext: { [weak self] data in
                let (tab, offset) = data
                self?.updateTopCardHeight(tab: tab, offset: offset)
            })
            .disposed(by: bag)
        
        /*
        homeViewModel.radarWillAppearSubject
            .subscribe(onNext: { [weak self] data in
                guard let this = self else { return }
                let (tab, offset) = data
                print2("radarWillAppearSubject \(tab)")
                this.updateTopCardHeight(tab: tab, offset: offset)
            })
            .disposed(by: bag)
        
        homeViewModel.homeTopCardHeightReseted
            .subscribe(onNext: { [weak self] tab in
                guard let this = self else { return }
                print2("homeTopCardHeightReseted \(tab)")
                this.resetTopCardHeight(tab: tab)
            })
            .disposed(by: bag)
        */
        
        homeViewModel.maximizeTopCardSubject
            .subscribe(onNext: { [weak self] _ in
                self?.maximazeTopCard()
            })
            .disposed(by: bag)
        
        homeViewModel.minimizeTopCardSubject
            .subscribe(onNext: { [weak self] _ in
                self?.minimizeTopCard()
            })
            .disposed(by: bag)
        
        homeViewModel.moreAdMobsRequiredSubject
            .subscribe(onNext: { [weak self] _ in
                self?.loadAdMobs()
            })
            .disposed(by: bag)
        
        HelperRepository.instance().myUserSubject
            .subscribe(onNext: { [weak self] (user: OrbisUser?) in
                self?.updateTopCard()
            })
            .disposed(by: bag)
        
        selectTab(tab: .map)
        
        setupAdMob()

        //showViewController(withInfo: .test)
        //print2("Bundle isSandbox: \(isSandbox()) isProduction: \(isProduction())")
        
        print2(UserDefaultsRepository.instance().getDebug() ?? "")
        UserDefaultsRepository.instance().setDebug(debug: nil)
        
        //tutorialView = TutorialView.createAndAttachToContainer(container: view)        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let tab = tabToShow {
            tabToShow = nil
            selectTab(tab: tab)
        }
    }
    
    private func updateTopCardViews(alpha: CGFloat) {
        registeredViewsWithoutGroupContainer.subviews.forEach { view in view.alpha = alpha }
        registeredViewsWithGroupContainer.subviews.forEach { view in view.alpha = alpha }
        notRegisteredViewsContainer.subviews.forEach { view in view.alpha = alpha }
        settingsButton.alpha = alpha
    }
    
    /*
        Bigger the offset, smaller the top card
     */
    private func updateTopCardHeight(tab: RadarTab, offset: CGFloat) {
        var currentOffset = radarOffset[tab]!
        currentOffset += offset
        currentOffset = max(currentOffset, 0.0)
        currentOffset = min(currentOffset, topCardDefHeight)
        radarOffset[tab] = currentOffset
        
        var topCardHeight = topCardDefHeight - currentOffset
        topCardHeight = max(topCardHeight, topCardMinHeight)
        topCardHeight = min(topCardHeight, topCardDefHeight)
        topCardHeightConstraint.constant = topCardHeight
        
        //let alpha = 1.0 - (topCardMinHeight / topCardHeight)
        let alpha = (topCardHeight - topCardMinHeight) / (topCardDefHeight - topCardMinHeight)
        updateTopCardViews(alpha: alpha)
        
        //print2("updateTopCardHeight tab: \(tab) radarOffset: \(currentOffset) offset: \(offset) topCardHeight: \(topCardHeight) alpha: \(alpha)")
    }
    
    private func resetTopCardHeight(tab: RadarTab)
    {
        radarOffset[RadarTab.myFeed] = 0.0
        radarOffset[RadarTab.distanceFeed] = 0.0
        updateTopCardHeight(tab: tab, offset: 0.0)
    }
    
    private func maximazeTopCard() {
        UIView.animate(withDuration: topCardHeightAnimDuration, animations: {
            self.topCardHeightConstraint.constant = self.topCardDefHeight
            self.updateTopCardViews(alpha: 1.0)
            self.view.layoutIfNeeded()
        })
    }
    
    private func minimizeTopCard() {
        UIView.animate(withDuration: topCardHeightAnimDuration, animations: {
            self.topCardHeightConstraint.constant = self.topCardMinHeight
            self.updateTopCardViews(alpha: 0.0)
            self.view.layoutIfNeeded()
        })
    }
    
    private func updateTopCard() {
        let udr = UserDefaultsRepository.instance()
        let user = udr.getMyUser()
        let group = udr.getActiveGroup()
    
        //print2("updateTopCard user.uid: \(user?.uid ?? "") user.name: \(user?.username ?? "")")
        
        if user == nil {
            registeredViewsWithGroupContainer.isHidden = true
            registeredViewsWithoutGroupContainer.isHidden = true
            notRegisteredViewsContainer.isHidden = false
            settingsButton.isHidden = true
        }
        else {
            usernameLabel.text = user?.username
            usernameLabel2.text = user?.username
            notRegisteredViewsContainer.isHidden = true
            settingsButton.isHidden = false
        
            if group == nil {
                registeredViewsWithoutGroupContainer.isHidden = false
                registeredViewsWithGroupContainer.isHidden = true
            }
            else {
                registeredViewsWithoutGroupContainer.isHidden = true
                registeredViewsWithGroupContainer.isHidden = false
                groupImageView.loadGroupImage(group: group)
                groupNameLabel.text = group?.name
            }
        }
    }
    
    override func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        super.onActiveGroupChanged(prevGroup: prevGroup, newGroup: newGroup)
        updateTopCard()
    }
    
    private func selectTab(tab: HomeTab) {
        switch tab {
        case .radar:
            tabRadarButton.isSelected = true
            tabMapButton.isSelected = false
            tabGroupsButton.isSelected = false
            appDelegate().setupRemoteNotifications(application: UIApplication.shared, requestAuthorizationIfNeeded: true)
            
        case .map:
            tabRadarButton.isSelected = false
            tabMapButton.isSelected = true
            tabGroupsButton.isSelected = false
            resetTopCardHeight(tab: .myFeed)
            resetTopCardHeight(tab: .distanceFeed)
            
        case .groups:
            tabRadarButton.isSelected = false
            tabMapButton.isSelected = false
            tabGroupsButton.isSelected = true
            resetTopCardHeight(tab: .myFeed)
            resetTopCardHeight(tab: .distanceFeed)
        }
    
        homeViewModel.tabSelected(tab: tab)
    }

    /*
        Para descobrir o código da linguagem:
        Selecionar o localizable.strings e ver o caminho nas propriedades do arquivo (canto superior direito)
        https://localise.biz/free/converter/ios-to-android
     */
    private func testLocalization() {
        let words = [Words.active, Words.changeGroup]
        
        UserDefaultsRepository.instance().setLanguage(language: OrbisLanguage.english)
        
        for word in words {
            print2("testLocalization \(word.rawValue) \(word.localized)")
        }
        
        UserDefaultsRepository.instance().setLanguage(language: OrbisLanguage.portugueseBR)
        
        for word in words {
            print2("testLocalization \(word.rawValue) \(word.localized)")
        }
        
        UserDefaultsRepository.instance().setLanguage(language: nil)
        
        for word in words {
            print2("testLocalization \(word.rawValue) \(word.localized)")
        }
    }
    
    private func setupAdMob() {
        print2("[AdMob] setup")
        
        let options = GADMultipleAdsAdLoaderOptions()
        options.numberOfAds = 1
        
        let adUnitID: String
        if isProduction() {
            adUnitID = "ca-app-pub-6738139926979321/2376798785"
        }
        else {
            adUnitID = "ca-app-pub-6738139926979321/3111686251"
        }
        
        adLoader = GADAdLoader(adUnitID: adUnitID,
                            rootViewController: self,
                            adTypes: [.unifiedNative],
                            options: [options])
        
        adLoader!.delegate = self
    }
    
    private func loadAdMobs() {
        print2("[AdMob] loadAdMobs [1]")
        
        guard let loader = adLoader, !loader.isLoading else { return }
        
        print2("[AdMob] loadAdMobs [2]")
        
        let request = GADRequest()
        
        if isSandbox() {
            request.testDevices = ["1b763776558365882da5db81ea614dc1"]
        }

        loader.load(request)
    }
    
    private func onAdMobLoaded(ad: GADUnifiedNativeAd) {
        print2("[AdMob] [HomeViewController] onAdMobLoaded")
        HomeViewModel.instance().onAdMobLoaded(ad: ad)
    }
    
}

extension HomeViewController : GADAdLoaderDelegate {
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        //print2("[AdMob] didFailToReceiveAdWithError \(error)")
    }

    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        //print2("[AdMob] adLoaderDidFinishLoading")
    }
    
}

extension HomeViewController : GADUnifiedNativeAdLoaderDelegate {
 
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        print2("[AdMob] [HomeViewController] Received native ad: \(nativeAd)")
        onAdMobLoaded(ad: nativeAd)
    }
    
}

extension HomeViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            // Disable your app's location features
            locationManager.stopUpdatingLocation()
            break
            
        case .authorizedWhenInUse:
            // Enable only your app's when-in-use features.
            locationManager.startUpdatingLocation()
            break
            
        case .authorizedAlways:
            // Enable any of your app's location services.
            locationManager.startUpdatingLocation()
            break
            
        case .notDetermined:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        //print2("Location: \(location.coordinate.latitude) \(location.coordinate.longitude)")
        HelperRepository.instance().setLocation(location: Coordinates(clLocation: location))
    }

}
