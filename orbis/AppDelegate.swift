//
//  AppDelegate.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 04/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseDatabase
import AWSMobileClient
import FBSDKCoreKit
import TwitterKit
import UserNotifications
import MKProgress
import PKHUD
import RxSwift
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let bag = DisposeBag()
    private var remoteNotificationsInitialized = false
    
    public let applicationReloadedObservable = PublishSubject<Bool>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        Database.database().isPersistenceEnabled = true
        
        AWSMobileClient.sharedInstance().initialize { (state: UserState?, error: Error?) in
            print2("AWSMobileClient state: \(String(describing: state)) error: \(String(describing: error))")
        }
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //TWTRTwitter.sharedInstance().start(withConsumerKey:"8xKieYKZs3gmO4SfzMxEOTa77", consumerSecret:"0p5Ti5vIU4CpyHOE1PvhkiRBxL4HCgfIk0fUIbczfYJqAodB5N")
        //TWTRTwitter.sharedInstance().start(withConsumerKey:"224011230-A49iIWxa9oepAqpu363dHkYKWKFLyNWamWTUqovM", consumerSecret:"xOMNyILQJ1VcOx5npsgWTKqkxaVHpQtVoJ13fln15kmdh")
        
        setupRemoteNotifications(application: application, requestAuthorizationIfNeeded: false)
        
        if isSandbox() {
            GADMobileAds.configure(withApplicationID: "ca-app-pub-3940256099942544~1458002511")
        }
        else if isProduction() {
            GADMobileAds.configure(withApplicationID: "ca-app-pub-6738139926979321~9820174532")
        }
        
        HelperRepository.instance().applicationFinishLaunchingSubject.onNext(true)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled = ApplicationDelegate.shared.application(app, open: url, options: options)
        print2("AppDelegate::openUrl FB handled: \(handled)")
        
        if !handled {
            handled = TWTRTwitter.sharedInstance().application(app, open: url, options: options)
            print2("AppDelegate::openUrl Twitter handled: \(handled)")
        }
        
        return handled
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return ApplicationDelegate.shared.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func reloadApplication(navController: UINavigationController?) {
        MKProgress.show()
        HomeViewModel.recreate()
        MapViewModel.recreate()
        
        navController?.popToRootViewController(animated: false)
        applicationReloadedObservable.onNext(true)
        
        delay(ms: 2000, block: {
            let storyboard = UIStoryboard(name: Storyboards.home.rawValue, bundle: nil)
            let vc = storyboard.instantiateInitialViewController()
            self.window?.rootViewController = vc
            MKProgress.hide()
        })
    }
    
    func setupRemoteNotifications(application: UIApplication, requestAuthorizationIfNeeded: Bool) {
        if remoteNotificationsInitialized {
            return
        }
       
        let notificationCenter = UNUserNotificationCenter.current()
        
        if requestAuthorizationIfNeeded {
            remoteNotificationsInitialized = true
        
            notificationCenter
                .requestAuthorization(options: [.alert, .sound, .badge]) {
                    granted, error in
                    print2("[Push] Permission granted: \(granted)")
                    if let error = error {
                        print2("[Push] Request permission error \(error)")
                    }
                }
            
            UNUserNotificationCenter.current().delegate = self
            application.registerForRemoteNotifications()
            Messaging.messaging().delegate = self
        }
        else {
            notificationCenter.getNotificationSettings { [weak self] (settings: UNNotificationSettings) in
                if settings.authorizationStatus == .authorized {
                    print2("[Push] Permission already granted")
                    self?.remoteNotificationsInitialized = true
                    
                    mainAsync {
                        UNUserNotificationCenter.current().delegate = self
                        application.registerForRemoteNotifications()
                        Messaging.messaging().delegate = self
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print2("[Push] didFailToRegisterForRemoteNotificationsWithError error: \(error)")
    }
    
    // Called on foreground. Don't know if its called on foreground too
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print2("[Push] didReceiveRemoteNotification")
        print2(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

/*
    https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html
 */
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        print2("[Push] userNotificationCenter openSettingsFor")
    }
    
    // Called on notification click
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print2("[Push] userNotificationCenter didReceive \(response.actionIdentifier)")
        print2("[Push] userNotificationCenter didReceive \(response.notification.request.content.userInfo)")
        
        switch response.actionIdentifier {
            
        // The user dismissed the notification without taking action
        case UNNotificationDismissActionIdentifier:
            break
           
        // The user launched the app
        case UNNotificationDefaultActionIdentifier:
            openNotification(userInfo: response.notification.request.content.userInfo, completionHandler: completionHandler)
            return
            
        default:
            break
        }

        // Must be executed after notification is processed, to let system know that you are done
        completionHandler()
    }
    
    // Called when a notification is delivered to a foreground app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        var ignore = false
        let myUser = UserDefaultsRepository.instance().getMyUser()
        let userInfo = notification.request.content.userInfo
        
        if false == myUser?.pushNotificationsEnabled {
            ignore = true
        }
        else if let senderId = userInfo[NotificationKey.senderId.rawValue] as? String,
            senderId == UserDefaultsRepository.instance().getMyUser()?.uid {
            ignore = true
        }
        else if
            let requestCodeValue = userInfo[NotificationKey.requestCode.rawValue] as? String,
            let requestCode = RequestCode.from(value: requestCodeValue),
            let postTypeValue = userInfo[NotificationKey.postType.rawValue] as? String,
            let postType = PostType.init(rawValue: postTypeValue),
            let myLocation = HelperRepository.instance().getLocation(),
            let coordinatesValue = userInfo[NotificationKey.coordinates.rawValue] as? String,
            let coordinatesData = coordinatesValue.data(using: .utf8),
            let postCoordinates = try? JSONDecoder().decode(Coordinates.self, from: coordinatesData),
            requestCode == RequestCode.openPost,
            postType.isLimitedByDistance(),
            myLocation.distanceInMeters(toOther: postCoordinates) > feedsByDistanceInMeters {
            ignore = true
        }
        
        print2("userNotificationCenter willPresent ignore: \(ignore)")
        
        if ignore {
            completionHandler([])
        }
        else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    private func openNotification(userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        guard let topViewController = UIApplication.shared.topViewController() else {
            let debug = "[DEBUG] UIApplication.topViewController is null"
            UserDefaultsRepository.instance().setDebug(debug: debug)
            completionHandler()
            return
        }

        guard let orbisViewController = topViewController as? OrbisViewController else {
            let debug = "[DEBUG] UIApplication.topViewController is not OrbisViewController"
            UserDefaultsRepository.instance().setDebug(debug: debug)
            completionHandler()
            return
        }
        
        guard
            let requestCodeValue = userInfo[NotificationKey.requestCode.rawValue] as? String,
            let requestCode = RequestCode.from(value: requestCodeValue)
        else {
            completionHandler()
            return
        }
    
        print2("[Push] requestCodeValue: \(requestCodeValue) requestCode: \(requestCode)")
    
        switch requestCode {
        
        case .openChat:
            openChat(viewController: orbisViewController, requestCode: requestCode, userInfo: userInfo, completionHandler: completionHandler)
            
        case .openComment:
            openComment(viewController: orbisViewController, requestCode: requestCode, userInfo: userInfo, completionHandler: completionHandler)
            
        case .openPost:
            openComment(viewController: orbisViewController, requestCode: requestCode, userInfo: userInfo, completionHandler: completionHandler)
            
        case .liked:
            openComment(viewController: orbisViewController, requestCode: requestCode, userInfo: userInfo, completionHandler: completionHandler)
            
        case .joined:
            openGroup(viewController: orbisViewController, requestCode: requestCode, userInfo: userInfo, completionHandler: completionHandler)
            
        default:
            break
        }
    }
    
    private func openChat(viewController: OrbisViewController, requestCode: RequestCode, userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        guard
            let senderId = userInfo[NotificationKey.senderId.rawValue] as? String,
            let receiverId = userInfo[NotificationKey.receiverId.rawValue] as? String,
            let chatKey = userInfo[NotificationKey.chatKey.rawValue] as? String
        else {
            completionHandler()
            return
        }
        
        let data = ChatNotificationData(requestCode: requestCode, senderId: senderId, receiverId: receiverId, chatKey: chatKey)
        viewController.handlePushNotificationData(pnData: data, completionHandler: completionHandler)
    }
    
    private func openComment(viewController: OrbisViewController, requestCode: RequestCode, userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        guard
            let postKey = userInfo[NotificationKey.postKey.rawValue] as? String,
            let senderId = userInfo[NotificationKey.senderId.rawValue] as? String
        else {
            completionHandler()
            return
        }
        
        if senderId == UserDefaultsRepository.instance().getMyUser()?.uid {
            return
        }
        
        PostDAO.loadWrapper(postKey: postKey, activeGroup: UserDefaultsRepository.instance().getActiveGroup())
            .subscribe(onSuccess: { wrapper in
                guard let wrapper = wrapper else {
                    completionHandler()
                    return
                }
                
                let data = CommentReceivedData(requestCode: requestCode, postWrapper: wrapper)
                viewController.handlePushNotificationData(pnData: data, completionHandler: completionHandler)
                
            }, onError: { error in
                print2(error)
                completionHandler()
            })
            .disposed(by: bag)
    }
    
    private func openGroup(viewController: OrbisViewController, requestCode: RequestCode, userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        guard
            let groupKey = userInfo[NotificationKey.groupKey.rawValue] as? String
        else {
            completionHandler()
            return
        }
    
        GroupDAO.findByKey(groupKey: groupKey)
            .subscribe(onSuccess: { group in
                guard let group = group else {
                    completionHandler()
                    return
                }
                
                let data = OpenGroupNotificationData(requestCode: requestCode, group: group)
                viewController.handlePushNotificationData(pnData: data, completionHandler: completionHandler)
            }, onError: { error in
                print2(error)
                completionHandler()
            })
            .disposed(by: bag)
    }
}

extension AppDelegate : MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print2("[Push] didReceiveRegistrationToken \(fcmToken)")
        
        guard let user = UserDefaultsRepository.instance().getMyUser() else { return }
        UserDAO.saveFcmToken(userId: user.uid, token: fcmToken)
            .subscribe(onCompleted: {
                print2("[Push] token saved")
            }, onError: { error in
                print2("[Push] token save error")
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print2("[Push] didReceiveRemoteMessage")
    }
    
}
