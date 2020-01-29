//
//  BasePostsViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class BasePostsViewController<VM : BasePostsViewModel & PostsViewModelContract> : OrbisViewController, PostCellDelegate {

    var tableView: UITableView!
    var emptyImageView: UIImageView!
    
    var postsViewModel: VM!
    var postsDataSource: BasePostsTableDataSource<VM>!
    var postsDelegate: BasePostsTableDelegate<VM>!
    
    private weak var reportAlert: UIAlertController?
    private var shareHelper: ShareHelper?
    private var currentPlayerKey: String?
    private var ignoreNextWillAppear = false
    
    let likesViewModel = LikesViewModel.instance()
    
    private lazy var reportViewModel: ReportViewModel = { [unowned self] in
        return ReportViewModel()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if postsViewModel.placedOnHome() {
            if shouldResetHomeTopCardHeight(offset: postsDelegate.tableOffset) {
                tableView.scrollToTop(animated: false)
                HomeViewModel.instance().topCardHeightReseted(by: postsViewModel.radarTab()!)
            }
            else {
                HomeViewModel.instance().radarWillAppear(tab: postsViewModel.radarTab()!, contentOffset: tableView.contentOffset.y)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if postsViewModel.placedOnHome() {
            let homeViewModel = HomeViewModel.instance()
            homeViewModel.radarDidAppear(tab: postsViewModel.radarTab()!, contentOffset: tableView.contentOffset.y)
        }
    }
    
    override func onActiveGroupChanged(prevGroup: Group?, newGroup: Group?) {
        super.onActiveGroupChanged(prevGroup: prevGroup, newGroup: newGroup)
        postsDataSource?.activeGroup = newGroup
        tableView?.reloadData()
    }
    
    override func handleTableOperation(operation: TableOperation, tableView: UITableView?) {
        super.handleTableOperation(operation: operation, tableView: tableView)
        if postsViewModel.numberOfItems() == 0 {
            emptyImageView.isHidden = false
        }
        else {
            emptyImageView.isHidden = true
        }
    }
    
    func configPostsTableView(container: UIView) {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.anchorToView(view: container, makeChild: true)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.hideUndesiredSeparators()

        tableView.register(cell: Cells.checkInPostCell)
        tableView.register(cell: Cells.imagePostCell)
        tableView.register(cell: Cells.lostPlacePostCell)
        tableView.register(cell: Cells.textPostCell)
        tableView.register(cell: Cells.videoPostCell)
        tableView.register(cell: Cells.videoPostCell2)
        tableView.register(cell: Cells.videoPostCell3)
        tableView.register(cell: Cells.wonPlacePostCell)
        tableView.register(cell: Cells.adMobCell)
        tableView.register(cell: Cells.evenGroupCell)
        
        /*
            for id in postsViewModel.videoReuseIdentifiers {
                tableView.register(cell: Cells.videoPostCell3, customIdentifier: id)
            }
         */
        
        tableView.allowsSelection = false
        tableView.dataSource = postsDataSource
        tableView.delegate = postsDelegate
        
        if postsViewModel.placedOnHome() {
            tableView.bounces = false
        }
        
        emptyImageView = UIImageView(image: UIImage(named: "tab_feeds_inactive"))
        emptyImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyImageView.contentMode = .scaleAspectFit
        emptyImageView.isHidden = true
        emptyImageView.anchorToView(view: container, makeChild: true, constant: 80)
    }
    
    func observePostsViewModel() {
        observeDefaultSubject(subject: postsViewModel.baseSubject)
        
        postsViewModel.tableOperationSubject
            .subscribe(onNext: { [weak self] operation in
                self?.handleTableOperation(operation: operation, tableView: self?.tableView)
            })
            .disposed(by: bag)

        if postsViewModel.placedOnHome() {
            HomeViewModel.instance().homeTopCardHeightReseted
                .subscribe(onNext: { [weak self] tab in
                    guard
                        let this = self,
                        this.postsViewModel.radarTab() != tab
                        else {
                            return
                    }
                    
                    this.postsDelegate.setOffset(offset: this.tableView.contentOffset.y)
                })
                .disposed(by: bag)
        }
        
        postsViewModel.onViewControllerReady()
    }
    
    func observeLikesViewModel() {
        likesViewModel.myLikeChangedSubject
            .subscribe(onNext: { [weak self] result in
                let (likeType, likeInfo) = result
                self?.processMyLikeChange(likeType: likeType, likeInfo: likeInfo)
            })
            .disposed(by: bag)
    }
    
    func observeHiddenPostsViewModel() {
        HiddenPostViewModel.instance()
            .myHiddenPostChangedSubject
            .subscribe(onNext: { [weak self] hiddenPost in
                self?.removePost(postKey: hiddenPost.postKey)
            })
            .disposed(by: bag)
    }
    
    func processMyLikeChange(likeType: LikeType, likeInfo: LikeInfo) {
        guard let index = postsViewModel.tableIndexOf(postKey: likeInfo.mainKey) else {
            return
        }
        tableView.reloadRows(at: [index.toIndexPath()], with: .none)
    }
    
    func removePost(postKey: String?) {
        postsViewModel.removePost(postKey: postKey)
    }
    
    func shouldPlay(indexPath: IndexPath?) -> Bool {
        guard let indexPath = indexPath else {
            return false
        }
        
        let value = indexPath.row == postsViewModel.tableIndexOf(postKey: postsDelegate.currentVideoKey)
        print2("shouldPlay row: \(indexPath.row) \(value)")
        return value
    }
    
    func placeClick(cell: UITableViewCell?) {
        print2("Place click [1]")
        
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath,
            let placeWrapper = postsViewModel.getPlaceWrapper(indexPath: indexPath)
        else {
            return
        }
        
        print2("Place click [2]")

        handleNavigation(navigation: Navigation.place(placeWrapper: placeWrapper))
    }
    
    func mainGroupClick(cell: UITableViewCell?) {
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
    
        let post = postsViewModel.getPost(indexPath: indexPath)
        guard let type = post.typeEnum() else { return }
        var group: Group?
        
        switch type {
        case .lostPlace:
            group = postsViewModel.getLoserGroup(post: post)
        default:
            group = postsViewModel.getWinnerGroup(post: post)
        }
    
        if let group = group {
            handleNavigation(navigation: Navigation.group(group: group))
        }
    }
    
    func loserGroupClick(cell: UITableViewCell?) {
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        if let g = postsViewModel.getLoserGroup(post: post) {
            handleNavigation(navigation: Navigation.group(group: g))
        }
    }
    
    func winnerGroupClick(cell: UITableViewCell?) {
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        if let g = postsViewModel.getWinnerGroup(post: post) {
            handleNavigation(navigation: Navigation.group(group: g))
        }
    }
    
    func userClick(cell: UITableViewCell?) {
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        if let user = postsViewModel.getUser(post: post) {
            handleNavigation(navigation: Navigation.user(user: user))
        }
    }
    
    func likeClick(cell: UITableViewCell?) {
        if !UserDefaultsRepository.instance().hasMyUser() {
            showOkAlert(title: Words.error, msg: Words.errorNoUserLikePost)
            return
        }
        
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        likesViewModel.toggleLike(likeType: LikeType.post, mainKey: post.postKey, postKey: post.postKey, receiverId: post.userKey)
    }
    
    func commentClick(cell: UITableViewCell?) {
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
        
        let wrapper = postsDataSource.getPostWrapper(indexPath: indexPath)
        handleNavigation(navigation: Navigation.comments(postWrapper: wrapper))
    }
    
    func shareClick(cell: UITableViewCell?) {
        print2("shareClick")
        
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        if shareHelper == nil {
            shareHelper = ShareHelper()
            
            shareHelper?.sharedItemsSubject
                .subscribe(onNext: { [weak self] items in
                    guard let this = self else { return }
                    print2("observed sharedItemsSubject")
                    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = this.view
                    this.present(activityViewController, animated: true, completion: nil)
                })
                .disposed(by: bag)
        
            observeDefaultSubject(subject: shareHelper!.defaultSubject)
        }
    
        shareHelper?.share(post: post)
    }
    
    func playClick(cell: VideoPostCell3) {
    }
    
    func pauseClick(cell: VideoPostCell3) {
    }
    
    func refreshClick(cell: UITableViewCell) {
    }
    
    func fullscreenClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        handleNavigation(navigation: Navigation.video(post: post))
    }
    
    func imageClick(cell: UITableViewCell?, tag: Int?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
            else {
                return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        handleNavigation(navigation: Navigation.gallery(post: post, imageIndex: tag))
    }
    
    func dotsClick(cell: UITableViewCell?) {
        guard
            let cell = cell as? BasePostCell,
            let indexPath = cell.indexPath
        else {
            return
        }
        
        let post = postsViewModel.getPost(indexPath: indexPath)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        print2((post.debug()))
        
        for option in PostMenuOptions.allCases {
            alert.addAction(UIAlertAction(title: option.getWord().localized, style: .default, handler: { [weak self] _ in
                switch option {
                case .reportPost:
                    self?.showReportAlert(post: post)
                default:
                    self?.postsViewModel.handle(option: option, post: post)
                }
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: Words.cancel.localized, style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func isPlaying(cell: VideoPostCell3) -> Bool {
        guard let cellKey = key(for: cell) else {
            print2("[VIDEO] isPlaying: cell key/url not defined")
            return false
        }
        
        print2("[VIDEO] isPlaying \(String(describing: cellKey)) \(String(describing: currentPlayerKey))")
        
        return cellKey == currentPlayerKey
    }
    
    private func key(for cell: VideoPostCell3) -> String? {
        guard let url = cell.url else { return nil }
        //return url.absoluteString + cell.hashValue.string
        return url.absoluteString
    }
    
    private func showReportAlert(post: OrbisPost) {
        reportAlert = showAlertWithTextField(
            title: Words.whyInnapropriate.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: true,
            textFieldDelegate: nil,
            rightBlock: { [weak self] text in
                self?.reportViewModel.saveReport(post: post, message: text)
            }
        )
    }
}
