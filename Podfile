# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
use_frameworks!

workspace 'orbis.xcworkspace'

def orbis_pods
    project 'orbis.xcodeproj'
    pod 'RxSwift', '~> 5.0.0'
    pod 'RxCocoa', '~> 5.0.0'
    pod 'RxDataSources', '~> 4.0.1'
    pod 'RxGesture', '~> 3.0.1'
    pod 'RxOptional', '~> 4.1.0'
    pod 'RxKeyboard', '~> 1.0.0'
    pod 'RxAlamofire', '~> 5.1.0'

    pod 'FirebaseCore', '~> 6.3.2'
    pod 'FirebaseAuth', '~> 6.3.1'
    pod 'FirebaseDatabase', '~> 6.1.1'
    pod 'FirebaseDynamicLinks', '~> 4.0.5'
    pod 'FirebaseMessaging', '~> 4.1.7'
    pod 'FirebasePerformance', '~> 3.1.5'
    pod 'FirebaseFunctions', '~> 2.5.1'
    pod 'FirebaseFirestore', '~> 1.6.1'
    pod 'RxFirebaseDatabase', '~> 0.3.8'
    pod 'RxFirebaseAuth', '~> 2.4'
    pod 'RxFirebaseFunctions', '~> 0.3.8'
    
    pod 'Fabric', '~> 1.9.0'
    pod 'Crashlytics', '~> 3.12.0'
    pod 'Google-Mobile-Ads-SDK', '~> 7.51.0'
    
    # github.com/aws-amplify/aws-sdk-ios
    pod 'AWSMobileClient', '~> 2.12.0'
    pod 'AWSS3', '~> 2.12.0'
    pod 'AWSCognito', '~> 2.12.0'
    
    # pod 'MaterialComponents/ProgressView', '~> 73.0.0' For now useless -> don't have indeterminate mode
    pod 'MaterialComponents/Tabs', '~> 93.0.0'
    pod 'MaterialComponents/Tabs+ColorThemer', '~> 93.0.0'
    
    pod 'CodableFirebase', '~> 0.2.1'
    pod 'DefaultsKit', '~> 0.2.0'
    pod 'RSKImageCropper', '~> 2.2.1'
    pod 'GeoFire', :git => 'https://github.com/firebase/geofire-objc.git', :branch => 'master'
    pod 'PKHUD', '~> 5.2.1'
    pod 'Kingfisher', '~> 5.4.0'
    # pod 'PocketSVG', '~> 2.0'
    pod 'SwifterSwift', '~> 5.0.0'
    pod 'Dwifft', '~> 0.9'
    # pod 'VideoPlaybackKit', '~> 0.2.3'
    # pod 'AttributedLib', '~> 2.0'
    pod 'FBSDKCoreKit'
    pod 'FBSDKLoginKit'
    pod 'TwitterKit', '~> 3.4.2'
    pod 'MKProgress', '1.0.9'
    pod 'ObjectMapper', '~> 3.4.2'
    #pod 'RealmSwift', '~> 3.17.3'	
end

target 'orbis_sandbox' do
    orbis_pods
end

target 'orbis_production' do
    orbis_pods
end
