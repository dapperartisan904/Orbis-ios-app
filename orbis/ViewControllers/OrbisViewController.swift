//
//  OrbisViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import MapKit
import RxSwift
import RxCocoa
import FirebaseAuth
import Photos

class OrbisViewController : UIViewController {
    
    @IBOutlet weak var cardView: CardView!
    
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        makeNavigationBarTransparent()
        
        if shouldObserveActiveGroup() {
            observeActiveGroup()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func handleError(error: OrbisErrors) {
        if let word = error.word() {
            showOkAlert(title: Words.error.localized, msg: word.localized)
        }
    }
    
    private func handleError(error: CloudFunctionsErrors, extra: Any? = nil) {
        switch error {
        case .checkInNotAllowed:
            showOkAlert(title: Words.error.localized, msg: Words.errorCheckInNotAllowerd.localized)
        case .checkInAtTemporaryPlaceNotAllowed:
            showOkAlert(title: Words.error.localized, msg: Words.errorCheckInTemporaryPlace.localized)
        case .checkInWithGroupNotAllowed:
            let minutes = extra as? String ?? "1"
            let msg = String(format: Words.errorCheckInWithGroupNotAllowed.localized, minutes)
            showOkAlert(title: Words.error.localized, msg: msg)
        }
    }
    
    private func handleError(error: NSError) {
        switch error.code {
        case AuthErrorCode.userNotFound.rawValue:
            showOkAlert(title: Words.error.localized, msg: Words.errorUserNotExists.localized)
        
        case AuthErrorCode.wrongPassword.rawValue:
            showOkAlert(title: Words.error.localized, msg: Words.errorIncorrectPwd.localized)

        case AuthErrorCode.weakPassword.rawValue:
            showOkAlert(title: Words.error.localized, msg: Words.errorWeakPassword.localized)
            
        case AuthErrorCode.invalidCredential.rawValue:
            showOkAlert(title: Words.error.localized, msg: Words.errorBadUsername.localized)
        
        case AuthErrorCode.credentialAlreadyInUse.rawValue:
            showOkAlert(title: Words.error.localized, msg: Words.errorUsernameTaken.localized)
            
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            showOkAlert(title: Words.error.localized, msg: Words.errorUsernameTaken.localized)
        
        default:
            showOkAlert(title: Words.error.localized, msg: Words.error.localized)
        }
    }
    
    func handleAny(value: Any) {
        //print2("handleAny \(type(of: value))")
        
        if let error = value as? OrbisErrors {
            handleError(error: error)
            return
        }
        
        if let error = value as? CloudFunctionsErrors {
            handleError(error: error)
            return
        }
        
        if let error = value as? (CloudFunctionsErrors, Any?) {
            handleError(error: error.0, extra: error.1)
            return
        }
        
        if let error = value as? NSError {
            handleError(error: error)
            return
        }
        
        if let action = value as? OrbisAction {
            handleAction(action: action)
            return
        }
        
        if let word = value as? Words {
            handleWord(word: word)
            return
        }
        
        if let navigation = value as? Navigation {
            handleNavigation(navigation: navigation)
            return
        }
        
        if let popTo = value as? PopNavigation {
            handleNavigation(navigation: popTo)
            return
        }
        
        if let actionAndError = value as? ActionAndError {
            handleAction(action: actionAndError.0)
            handleWord(word: actionAndError.1)
            return
        }
        
        if let status = value as? TaskStatus {
            onTaskStatusChanged(status: status)
            return
        }
        
        if let tuple = value as? (Any, Any) {
            handleAny(value: tuple.0)
            handleAny(value: tuple.1)
            return
        }
    }
    
    func observeDefaultSubject(subject: PublishSubject<Any>, onlyIfVisible: Bool = false) {
        subject.asDriver(onErrorJustReturn: "").drive(onNext: { [weak self] value in
            guard let this = self else {
                return
            }
            
            if onlyIfVisible {
                guard let visibleVC = this.navigationController?.visibleViewController else {
                    return
                }

                if this.hashValue != visibleVC.hashValue {
                    return
                }
            }
            
            //print2("observeDefaultSubject [\(type(of: self))] value")
            this.handleAny(value: value)
        })
        .disposed(by: bag)
    }
    
    func observeDefaultSubjectWithoutBag(subject: PublishSubject<Any>) -> Disposable{
        return subject.asDriver(onErrorJustReturn: "").drive(onNext: { [weak self] value in
            self?.handleAny(value: value)
        })
    }
    
    func handleTableOperation(operation: TableOperation, tableView: UITableView?) {
        guard let tableView = tableView else { return }
        
        mainAsync {
            if let _ = operation as? TableOperation.ReloadOperation {
                tableView.reloadData()
            }
            else if let op = operation as? TableOperation.UpdateOperation {
                if let index = op.index {
                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
                if let paths = op.indexPaths {
                    tableView.reloadRows(at: paths, with: .none)
                }
            }
            else if let op = operation as? TableOperation.InsertOperation {
                if op.scroll {
                    tableView.insertRows(at: op.indexes(), with: .none)
                    delay(ms: 500, block: { tableView.scrollToRow(at: op.indexes().last!, at: UITableView.ScrollPosition.bottom, animated: true) })
                }
                else {
                    tableView.insertRows(at: op.indexes(), with: .automatic)
                    if self.shoulScrollToBottomOnAddition() {
                        tableView.scrollToBottom(animated: true)
                    }
                }
            }
            else if let op = operation as? TableOperation.DeleteOperation {
                tableView.deleteRows(at: [IndexPath(row: op.index, section: op.section)], with: UITableView.RowAnimation.fade)
            }
        }
    }
    
    func shouldObserveActiveGroup() -> Bool {
        return true
    }

    func shoulScrollToBottomOnAddition() -> Bool {
        return false
    }
    
    func observeActiveGroup() {
        HelperRepository
            .instance()
            .activeGroupSubject
            .subscribe(onNext: { [weak self] arg in
                self?.onActiveGroupChanged(prevGroup: arg.0, newGroup: arg.1)
                }, onError: nil
            )
            .disposed(by: bag)
    }
    
    func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        paintBackground(group: newGroup)
    }
    
    func paintBackground(group: Group?) {
        paintBackground(solidColorHex: group?.solidColorHex)
    }
    
    func paintBackground(solidColorHex: String?) {
        view.backgroundColor = UIColor(rgba: solidColorHex ?? "#FFFFFF")
    }
    
    func paintBackground(solidColorIndex: Int?) {
        if let index = solidColorIndex {
            paintBackground(solidColorHex: groupSolidColorHex(index: index))
        }
        else {
            paintBackground(solidColorHex: nil)
        }
     }
    
    // To be overriden when appropriate
    func onEmptyContent() { }
    func onTaskStarted() { }
    func onTaskFinished() { }
    func onTaskFailed() { }
    func onTaskStatusChanged(status: TaskStatus) { }
    
    func configSearchField(searchField: UITextField, delegate: SearchDelegate, searchString: Words) {
        let font = UIFont.systemFont(ofSize: 12)
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        let searchIcon = UIImage(named: "baseline_search_black_24pt")!
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - searchIcon.size.height).rounded() / 2, width: searchIcon.size.width, height: searchIcon.size.height)
        attachment.image = searchIcon
        
        let string = NSAttributedString(attachment: attachment)
        
        let attributedText = NSMutableAttributedString(attributedString: string)
        let searchString = NSAttributedString(string: "  " + searchString.localized)
        attributedText.append(searchString)
        searchField.attributedPlaceholder = attributedText
        searchField.font = font
        
        searchField.rx.text.asDriver().debounce(0.5)
            .drive(onNext: { (text: String?) in
                delegate.search(term: text)
            })
            .disposed(by: bag)
    }
    
    // We assume that word means error
    private func handleWord(word: Words) {
        var text: String
        switch word {
        case .invalidGroupDescription:
            text = word.localized.replacingOccurrences(of: "%1$d", with: String(groupDescriptionMinLenght))
        default:
            text = word.localized
        }
        showOkAlert(title: Words.error.localized, msg: text)
    }
    
    private func handleAction(action: OrbisAction) {
        switch action {
        case .emptyContent:
            onEmptyContent()
        case .signIn:
            navigationController?.popToRootViewController(animated: true)
        case .signOut:
            navigationController?.popToRootViewController(animated: true)
        case .taskStarted:
            onTaskStarted()
        case .taskFinished:
            onTaskFinished()
        case .taskFailed:
            onTaskFailed()
        }
    }
    
    func handleNavigation(navigation: PopNavigation) {
        guard let vcs = navigationController?.viewControllers else {
            return
        }
        
        for vc in vcs.reversed() {
            if navigation.match(vc: vc) {
                navigationController?.popToViewController(vc, animated: true)
                break
            }
        }
    }
    
    func handleNavigation(navigation: Navigation) {
        DispatchQueue.main.async { [weak self] in
            guard let this = self else { return }
            
            let hr = HelperRepository.instance()
            switch navigation {
            case .group(let group):
                hr.selectGroup(group: group)
                let vc = this.createViewController(withInfo: .group) as! GroupViewController
                vc.groupViewModel = GroupViewModel(group: group)
                this.navigationController?.pushViewController(vc, animated: true)

            case .createGroup():
                let vc = this.createViewController(withInfo: .createGroup) as! CreateGroupViewController
                vc.viewModel = CreateGroupViewModel(group: nil)
                this.navigationController?.pushViewController(vc, animated: true)
                
            case .editGroup(let group):
                let vc = this.createViewController(withInfo: .createGroup) as! CreateGroupViewController
                vc.viewModel = CreateGroupViewModel(group: group)
                this.navigationController?.pushViewController(vc, animated: true)
                
            case .place(let placeWrapper):
                hr.selectPlace(wrapper: placeWrapper)
                let vc = this.createViewController(withInfo: .place) as! PlaceViewController
                vc.placeViewModel = PlaceViewModel(place: placeWrapper.place)
                this.navigationController?.pushViewController(vc, animated: true)
                
            case .user(let user):
                let vc = this.createViewController(withInfo: .user) as! UserViewController
                vc.userViewModel = UserViewModel(user: user)
                this.navigationController?.pushViewController(vc, animated: true)
                
            case .register():
                this.showViewController(withInfo: ViewControllerInfo.register)
                
            case .home():
                this.navigationController?.popToRootViewController(animated: true)
                
            case .map():
                if let vc = this.navigationController?.viewControllers[0] as? HomeViewController {
                    vc.tabToShow = HomeTab.map
                    this.navigationController?.popToRootViewController(animated: true)
                }
                
            case .chat(let viewModel):
                let vc = this.createViewController(withInfo: .chat) as! ChatViewController
                vc.view.frame = this.view.frame
                vc.chatViewModel = viewModel
                this.addChild(vc)
                this.view.addSubview(vc.view)
                vc.didMove(toParent: vc)
                
            case .chatGallery(let msg):
                guard
                    let str = msg.imageUrls?.first,
                    let url = S3Folder.chats.downloadURL(cloudKey: str)
                else {
                    return
                }
                let vc = this.createViewController(withInfo: .chatGallery) as! ChatGalleryViewController
                vc.url = url
                this.present(vc, animated: true, completion: nil)
                
            case .chatImageSelector(let chatViewModel):
                let vm = ChatImageSelectorViewModel(chatViewModel: chatViewModel)
                let vc = this.createViewController(withInfo: .chatImageSelector) as! ChatImageSelectorViewController
                vc.viewModel = vm
                this.navigationController?.pushViewController(vc)
                
            case .createPlaceStepTwo(let viewModel):
                let vc = this.createViewController(withInfo: .createPlaceStepTwo) as! CreatePlaceStepTwoViewController
                vc.viewModel = viewModel
                this.navigationController?.pushViewController(vc)
                
            case .createPostStepOne(let viewModel):
                let vc = this.createViewController(withInfo: .createPostStepOne) as! CreatePostStepOneViewController
                vc.viewModel = viewModel
                this.navigationController?.pushViewController(vc)
                
            case .createPostStepTwo(let viewModel):
                let vc = this.createViewController(withInfo: .createPostStepTwo) as! CreatePostStepTwoViewController
                vc.viewModel = viewModel
                this.navigationController?.pushViewController(vc)
                
            case .video(let post):
                this.showVideo(post: post)
                
            case .gallery(let post, let imageIndex):
                if post.imageUrls?.isEmpty ?? true {
                    return
                }
            
                let vc = this.createViewController(withInfo: .postGallery) as! PostGalleryViewController
                vc.galleryViewModel = PostGalleryViewModel(post: post, imageIndex: imageIndex)
                
                //let nav = UINavigationController(rootViewController: vc)
                this.present(vc, animated: true, completion: nil)
                
            case .comments(let postWrapper):
                let vc = this.createViewController(withInfo: .comments) as! CommentsViewController
                vc.commentsViewModel = CommentsViewModel(wrapper: postWrapper)
                this.navigationController?.pushViewController(vc)
            
            case .commentImageSelector(let commentsViewModel):
                let vc = this.createViewController(withInfo: .commentImageSelector) as! CommentImageSelectorViewController
                let vm = CommentImageSelectorViewModel(commentsViewModel: commentsViewModel)
                vc.viewModel = vm
                this.navigationController?.pushViewController(vc)
                
            case .createEvent(let viewModel):
                let vc = this.createViewController(withInfo: .createEvent) as! CreateEventViewController
                vc.viewModel = viewModel
                this.navigationController?.pushViewController(vc)
                
            case .attendances(let viewModel):
                let vc = this.createViewController(withInfo: .attendances) as! AttendancesViewController
                vc.viewModel = viewModel
                this.navigationController?.pushViewController(vc)
            }
        }
    }
    
    func handlePushNotificationData(pnData: OrbisPushNotificationData, completionHandler: @escaping () -> Void) {
        let debug =  "[DEBUG] Last top view controller that handled push notification: \(type(of: self))"
        print2(debug)
        UserDefaultsRepository.instance().setDebug(debug: debug)
        
        if let chatData = pnData as? ChatNotificationData {
            UserDAO.load(userId: chatData.senderId)
                .subscribe(onSuccess: { [weak self] user in
                    guard
                        let this = self,
                        let user = user
                    else {
                        completionHandler()
                        return
                    }
                
                    this.handleNavigation(navigation: Navigation.user(user: user))
                    completionHandler()

                }, onError: { error in
                    print2(error)
                    completionHandler()
                })
                .disposed(by: bag)
        }
        else if let commentReceivedData = pnData as? CommentReceivedData {
            handleNavigation(navigation: Navigation.comments(postWrapper: commentReceivedData.postWrapper))
        }
        else if let groupData = pnData as? OpenGroupNotificationData {
            handleNavigation(navigation: Navigation.group(group: groupData.group))
        }
        else {
            completionHandler()
        }
    }
    
    func showPopup(_ controller: UIViewController, sourceView: UIView) {
        let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller)
        presentationController.sourceView = sourceView
        presentationController.sourceRect = sourceView.bounds
        presentationController.permittedArrowDirections = [.any]
        present(controller, animated: true)
    }

    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    private func showVideo(post: OrbisPost) {
        guard
            var cloudKey = post.imageUrls?.first,
            let downloadUrl = S3Folder.posts.downloadURL(cloudKey: cloudKey)
        else {
            return
        }
        
        cloudKey = cloudKey.deletingPathExtension
        showVideo(useCache: true, cloudKey: cloudKey, downloadUrl: downloadUrl)
    }
    
    private func showVideo(useCache: Bool, cloudKey: String, downloadUrl: URL) {
        print2("showVideo useCache: \(useCache) cloudKey: \(cloudKey) downloadUrl: \(downloadUrl)")
        
        if useCache {
            guard let phAssetId = UserDefaultsRepository.instance().getPHAssetId(postImageId: cloudKey) else {
                showVideo(useCache: false, cloudKey: cloudKey, downloadUrl: downloadUrl)
                return
            }
            
            let options = PHFetchOptions()
            options.fetchLimit = 1
            options.includeAllBurstAssets = false
            
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [phAssetId], options: options)
            guard let asset = result.firstObject else {
                showVideo(useCache: false, cloudKey: cloudKey, downloadUrl: downloadUrl)
                return
            }
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { [weak self] (avAsset: AVAsset?, avAudioMix: AVAudioMix?, dict: [AnyHashable : Any]?) in
                guard let _ = self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard
                        let this = self,
                        let avAsset = avAsset
                    else {
                        self?.showVideo(useCache: false, cloudKey: cloudKey, downloadUrl: downloadUrl)
                        return
                    }
                    
                    print2("showVideo from cache")
                
                    let playerItem = AVPlayerItem(asset: avAsset)
                    let videoPlayerVC = this.createViewController(withInfo: .videoPlayer) as! AVPlayerViewController
                    videoPlayerVC.player = AVPlayer(playerItem: playerItem)
                    this.present(videoPlayerVC, animated: true, completion: {
                        videoPlayerVC.player?.play()
                    })
                }
            })
        }
        else {
            print2("showVideo from cloud")
            
            let player = AVPlayer(url: downloadUrl)
            let videoPlayerVC = createViewController(withInfo: .videoPlayer) as! AVPlayerViewController
            videoPlayerVC.player = player
            present(videoPlayerVC, animated: true, completion: {
                videoPlayerVC.player?.play()
            })
        }
    }
    
    func openMapsWithDirections(name: String?, coordinates: CLLocationCoordinate2D) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinates, addressDictionary: nil))
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    func openMapWithAddress(address: String) {
        if #available(iOS 11.0, *) {
            CLGeocoder().geocodeAddressString(address, in: nil, preferredLocale: nil) { [weak self] (placeMarks: [CLPlacemark]?, error: Error?) in
                if let e = error {
                    print2("openMapWithAddress error: \(e)")
                    return
                }
                
                guard let placeMark = placeMarks?.first else {
                    print2("openMapWithAddress no results")
                    return
                }
        
                guard let location = placeMark.location else {
                    print2("openMapWithAddress result has no location")
                    return
                }
                
                self?.openMapsWithDirections(name: nil, coordinates: location.coordinate)
            }
        }
    }
}

extension OrbisViewController : ToolbarDelegate {

    func backClick() {
        print2("backClick")
        navigationController?.popViewController(animated: true)
    }
    
    func homeClick() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    func settingsClick() {
        showViewController(withInfo: ViewControllerInfo.settings)
    }
    
    @objc func dotsClick() {
        // Should be overriden on vcs extending OrbisViewController
    }
    
    @objc func toolbarTitleClick() {
        // Should be overriden on vcs extending OrbisViewController
    }
    
}
