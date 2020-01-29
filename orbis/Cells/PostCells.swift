//
//  PostCells.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import Kingfisher
//import VideoPlaybackKit
import RxSwift
import RxCocoa
import RxGesture
//import AttributedLib
import SwifterSwift

protocol PostCellDelegate : class {
    func shouldPlay(indexPath: IndexPath?) -> Bool
    func playClick(cell: VideoPostCell3)
    func pauseClick(cell: VideoPostCell3)
    func isPlaying(cell: VideoPostCell3) -> Bool
    func placeClick(cell: UITableViewCell?)
    func mainGroupClick(cell: UITableViewCell?)
    func loserGroupClick(cell: UITableViewCell?)
    func winnerGroupClick(cell: UITableViewCell?)
    func userClick(cell: UITableViewCell?)
    func likeClick(cell: UITableViewCell?)
    func shareClick(cell: UITableViewCell?)
    func refreshClick(cell: UITableViewCell)
    func fullscreenClick(cell: UITableViewCell?)
    func imageClick(cell: UITableViewCell?, tag: Int?)
    func commentClick(cell: UITableViewCell?)
    func dotsClick(cell: UITableViewCell?)
}

class PostCellFooter : UIView {
    @IBOutlet weak var likeClickView: UIView!
    @IBOutlet weak var commentClickView: UIView!
    @IBOutlet weak var shareClickView: UIView!
    
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var chatButton: UIImageView!
    @IBOutlet weak var shareButton: UIImageView!
    
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
}

class PostCellSocialHeader : UIView {
    @IBOutlet weak var groupImageView: RoundedImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dotsButton: UIImageView!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var placeIcon: UIImageView!
}

/*
    Do not use a UITextView with NSAttributedString in place of eventLabels
    Click does not works inside UITableView
    On iOS it will have 3 lines instead of 2 (in opposite of Android)
 */
class PostCellGroupAndPlaceHeader : UIView {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dotsButton: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var eventLabel2: UILabel!
    @IBOutlet weak var eventLabel3: UILabel!
}

class BasePostCell : UITableViewCell {
    
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var footerContainer: UIView!

    weak var delegate: PostCellDelegate?
    weak var footer: PostCellFooter?
    
    private(set) var indexPath: IndexPath?
    let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        footer = UIView.loadFromNib(named: "PostCellFooter") as? PostCellFooter
        footer!.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(footer!)
        footer!.anchorToSuperview()

        footer?.commentClickView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.commentClick(cell: self)
            })
            .disposed(by: bag)
        
        footer?.likeClickView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.likeClick(cell: self)
            })
            .disposed(by: bag)
        
        footer?.shareClickView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.shareClick(cell: self)
            })
            .disposed(by: bag)
        
        footer?.usernameLabel.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.userClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    private func fillFooter(wrapper: PostWrapper) {
        footer?.usernameLabel.text = wrapper.user?.username
        footer?.likeLabel.text = (wrapper.counter?.likesCount ?? 0).string
        footer?.chatLabel.text = (wrapper.counter?.commentsCount ?? 0).string

        footer?.likeImageView.image = UIImage(named: "like")?.withAlignmentRectInsets(UIEdgeInsets(inset: -4)).template
        footer?.likeImageView.tintStroke(activeGroup: wrapper.activeGroup, isSelected: wrapper.isLiking)

        footer?.shareButton.image = UIImage(named: "share")?.withAlignmentRectInsets(UIEdgeInsets(inset: -4)).template
        footer?.shareButton.tintStroke(activeGroup: wrapper.activeGroup, isSelected: true)
        
        footer?.chatButton.image = UIImage(named: "baloon")?.withAlignmentRectInsets(UIEdgeInsets(inset: -4)).template
        footer?.chatButton?.tintStroke(activeGroup: wrapper.activeGroup, isSelected: true)
    }

    open func fill(wrapper: PostWrapper) {
        self.indexPath = wrapper.indexPath
        self.delegate = wrapper.cellDelegate
        fillFooter(wrapper: wrapper)
    }

}

class BaseGroupAndPlacePostCell : BasePostCell {
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var defaultFlagContainer: UIView!
    @IBOutlet weak var headerContainerHeightConstraint: NSLayoutConstraint!
    
    weak var header: PostCellGroupAndPlaceHeader?
    weak var defaultFlagView: FlagView?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        headerContainerHeightConstraint.constant = 150
        header = UIView.loadFromNib(named: "PostCellGroupAndPlaceHeader") as? PostCellGroupAndPlaceHeader
        header!.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(header!)
        header!.anchorToSuperview()
        defaultFlagView = FlagView.createAndAttachToContainer(container: defaultFlagContainer)
        
        headerContainer.isUserInteractionEnabled = true
        header!.isUserInteractionEnabled = true
        header!.eventLabel.isUserInteractionEnabled = true
        header!.eventLabel3.isUserInteractionEnabled = true
        
        header!.eventLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        header!.eventLabel2.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        header!.eventLabel3.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)

        header!.dotsButton.isHidden = false
        
        defaultFlagView?.placeImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.placeClick(cell: self)
            })
            .disposed(by: bag)
        
        header?.eventLabel.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                print2("eventLabel click")
                self?.delegate?.mainGroupClick(cell: self)
            })
            .disposed(by: bag)
        
        header?.eventLabel3.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                print2("eventLabel3 click")
                self?.delegate?.placeClick(cell: self)
            })
            .disposed(by: bag)
        
        header?.dotsButton.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.dotsClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    func fillHeader(post: OrbisPost, group: Group?, place: Place?) {
        guard let header = header else { return }
        let timestamp = Double(post.serverTimestamp / 1000)
        header.dateLabel.text = Date(timeIntervalSince1970: timestamp).dateTimeString(ofStyle: .medium)
        
        guard
            let type = post.typeEnum(),
            let group = group,
            let place = place
        else {
            return
        }
    
        switch type {
        case .wonPlace, .conqueredPlace:
            header.eventLabel2.text = Words.conquered.localized.uppercased()
            header.imageView.image = UIImage(named: "crown")?.template
            
        case .lostPlace:
            header.eventLabel2.text = Words.lost.localized.uppercased()
            header.imageView.image = UIImage(named: "sad_face")?.template
            
        case .checkIn:
            header.eventLabel2.text = Words.checkIn.localized.uppercased()
            //header.imageView.image = UIImage(named: "place_location")?.filled(withColor: groupSolidColor(group: group))
            header.imageView.image = UIImage(named: "place_location")?.template
            
        case .event:
            header.eventLabel2.text = Words.createdAnEventAt.localized.uppercased()
            header.imageView.image = UIImage(named: "calendar")?.template
        
        default:
            return
        }
        
        header.eventLabel.text = group.name
        header.eventLabel.textColor = groupStrokeColor(group: group)
        header.eventLabel3.text = place.name
        header.imageView.tintColor = groupSolidColor(group: group)
    }
    
}

class BaseSocialPostCell : BasePostCell {
    
    weak var header: PostCellSocialHeader?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        header = UIView.loadFromNib(named: "PostCellSocialHeader") as? PostCellSocialHeader
        header!.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(header!)
        header!.anchorToSuperview()
        header!.placeIcon.tintColorDidChange()
        
        [header!.groupImageView, header!.groupNameLabel].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.mainGroupClick(cell: self)
                })
                .disposed(by: bag)
        }
        
        [header!.placeLabel, header!.placeIcon].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.placeClick(cell: self)
                })
                .disposed(by: bag)
        }
        
        header?.dotsButton.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.dotsClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    func fillHeader(post: OrbisPost, group: Group?, place: Place?) {
        header?.groupImageView.borderWidth = 1.0
        header?.groupImageView.loadGroupImage(group: group)
        header?.groupNameLabel.text = group?.name
        
        let timestamp = Double(post.serverTimestamp / 1000)
        header?.dateLabel.text = Date(timeIntervalSince1970: timestamp).dateTimeString(ofStyle: .medium)
        
        if let p = place {
            header?.placeIcon.isHidden = false
            header?.placeLabel.isHidden = false
            header?.placeLabel.text = p.name
        }
        else {
            header?.placeIcon.isHidden = true
            header?.placeLabel.isHidden = true
        }
    }
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        fillHeader(post: wrapper.post, group: wrapper.winnerGroup, place: wrapper.place)
    }
}

class WonPlacePostCell : BaseGroupAndPlacePostCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        defaultFlagView?.groupImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.mainGroupClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        fillHeader(post: wrapper.post, group: wrapper.winnerGroup, place: wrapper.place)
        defaultFlagView?.paint(group: wrapper.winnerGroup, place: wrapper.place)
    }
    
}

class CheckInCell : BaseGroupAndPlacePostCell {
    
    @IBOutlet weak var groupImageView: RoundedImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        groupImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.mainGroupClick(cell: self)
            })
            .disposed(by: bag)
        
        defaultFlagView?.groupImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.mainGroupClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        fillHeader(post: wrapper.post, group: wrapper.winnerGroup, place: wrapper.place)
        defaultFlagView?.paint(group: wrapper.winnerGroup, place: wrapper.place)
        groupImageView.loadGroupImage(group: wrapper.winnerGroup)
    }
    
}

class LostPlacePostCell : BaseGroupAndPlacePostCell {
    
    @IBOutlet weak var loserFlagContainer: UIView!
    
    weak var loserFlagView: FlagView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loserFlagView = FlagView.createAndAttachToContainer(container: loserFlagContainer)
        
        defaultFlagView?.groupImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.winnerGroupClick(cell: self)
            })
            .disposed(by: bag)
        
        loserFlagView?.groupImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.loserGroupClick(cell: self)
            })
            .disposed(by: bag)
        
        loserFlagView?.placeImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.placeClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        fillHeader(post: wrapper.post, group: wrapper.loserGroup, place: wrapper.place)
        defaultFlagView?.paint(group: wrapper.winnerGroup, place: wrapper.place)
        loserFlagView?.paint(group: wrapper.loserGroup, place: wrapper.place)
    }
    
}

class TextPostCell : BaseSocialPostCell {
    
    @IBOutlet weak var mainTextLabel: UILabel!
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        mainTextLabel.text = wrapper.post.details
    }

}

class ImagePostCell : BaseSocialPostCell {
    
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var moreImagesLabel: UILabel!
    
    @IBOutlet weak var singleImageView: CacheImageView!
    @IBOutlet weak var leftImageView: CacheImageView!
    @IBOutlet weak var rightImageView: CacheImageView!
    @IBOutlet weak var topLeftImageView: CacheImageView!
    @IBOutlet weak var topRightImageView: CacheImageView!
    @IBOutlet weak var bottomLeftImageView: CacheImageView!
    @IBOutlet weak var bottomRightImageView: CacheImageView!
    
    private func allImageViews() -> [UIImageView] {
        return [singleImageView, leftImageView, rightImageView, topLeftImageView, topRightImageView, bottomLeftImageView, bottomRightImageView]
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        var imageViews = allImageViews()
        for i in 0...imageViews.count-1 {
            var iv = imageViews[i]
            iv.kf.indicatorType = IndicatorType.activity
            (iv.kf.indicator?.view as? UIActivityIndicatorView)?.color = UIColor.white
            
            iv.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] recognizer in
                    self?.delegate?.imageClick(cell: self, tag: recognizer.view?.tag)
                })
                .disposed(by: bag)
        }
    }
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        guard let urls = wrapper.post.imageUrls else { return }
        
        mainTextLabel.text = wrapper.post.title

        switch urls.count {
        case 0:
            singleImageView.isHidden = true
            leftImageView.isHidden = true
            rightImageView.isHidden = true
            topLeftImageView.isHidden = true
            topRightImageView.isHidden = true
            bottomLeftImageView.isHidden = true
            bottomRightImageView.isHidden = true
            moreImagesLabel.isHidden = true
            
        case 1:
            singleImageView.isHidden = false
            leftImageView.isHidden = true
            rightImageView.isHidden = true
            topLeftImageView.isHidden = true
            topRightImageView.isHidden = true
            bottomLeftImageView.isHidden = true
            bottomRightImageView.isHidden = true
            moreImagesLabel.isHidden = true
            singleImageView.loadPostImage(url: urls[0])
            singleImageView.tag = 0
            
        case 2:
            singleImageView.isHidden = true
            leftImageView.isHidden = false
            rightImageView.isHidden = false
            topLeftImageView.isHidden = true
            topRightImageView.isHidden = true
            bottomLeftImageView.isHidden = true
            bottomRightImageView.isHidden = true
            moreImagesLabel.isHidden = true
            leftImageView.loadPostImage(url: urls[0])
            leftImageView.tag = 0
            rightImageView.loadPostImage(url: urls[1])
            rightImageView.tag = 1
            
        case 3:
            singleImageView.isHidden = true
            leftImageView.isHidden = false
            rightImageView.isHidden = true
            topLeftImageView.isHidden = true
            topRightImageView.isHidden = false
            bottomLeftImageView.isHidden = true
            bottomRightImageView.isHidden = false
            moreImagesLabel.isHidden = true
            leftImageView.loadPostImage(url: urls[0])
            leftImageView.tag = 0
            topRightImageView.loadPostImage(url: urls[1])
            topRightImageView.tag = 1
            bottomRightImageView.loadPostImage(url: urls[2])
            bottomRightImageView.tag = 2
            
        default:
            singleImageView.isHidden = true
            leftImageView.isHidden = true
            rightImageView.isHidden = true
            topLeftImageView.isHidden = false
            topRightImageView.isHidden = false
            bottomLeftImageView.isHidden = false
            bottomRightImageView.isHidden = false
            topLeftImageView.loadPostImage(url: urls[0])
            topLeftImageView.tag = 0
            topRightImageView.loadPostImage(url: urls[1])
            topRightImageView.tag = 1
            bottomLeftImageView.loadPostImage(url: urls[2])
            bottomLeftImageView.tag = 2
            bottomRightImageView.loadPostImage(url: urls[3])
            bottomRightImageView.tag = 3
            
            if urls.count > 4 {
                moreImagesLabel.text = "+\(urls.count-3)"
                moreImagesLabel.isHidden = false
            }
            else {
                moreImagesLabel.isHidden = true
            }
        }
    }
    
}

/*
    https://www.johnxiong.com/2017/03/14/quick-swift-play-video-in-uitableviewcell/
    Next step: test if cache AVPlayer works (keep an array on view model)
*/
class VideoPostCell3 : BaseSocialPostCell {
    
    @IBOutlet weak var videoImageView: VideoImageView!
    @IBOutlet weak var videoImageViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var playButton: UIImageView!
    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var postLabelConstraint: NSLayoutConstraint!
    
    private var player: AVPlayer!
    private(set) var url: URL?
    
    /*
    var url: URL? {
        return playerView.url
    }
    */
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print2("[VIDEO] prepareForReuse")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        playButton.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.fullscreenClick(cell: self)
            })
            .disposed(by: bag)
    }
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        
        //let videoURL = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
        //let player = AVPlayer(url: videoURL!)
        
        postLabel.text = wrapper.post.title
        
        /*
        if (wrapper.post.title?.isEmpty ?? true) {
            postLabelConstraint.constant = 0
        }
        else {
            postLabelConstraint.constant = 22
        }
        */
        
        guard
            var cloudKey = wrapper.post.imageUrls?.first,
            let url = S3Folder.posts.downloadURL(cloudKey: cloudKey)
        else {
            return
        }
        
        //videoImageView.kf.setImage(with: url)
        
        cloudKey = cloudKey.deletingPathExtension
        videoImageView.createThumbnailOfVideoIfNeeded(url: url, cloudKey: cloudKey, maxSize: videoImageView.size, indicatorView: videoImageViewIndicator)
        
        print2("[VIDEO] videoCloudKey: \(cloudKey) videoUrl: \(url) cell url: \(url.absoluteString)")
        
        /*
        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = true
        playerView.playerLayer.player = avPlayer

        self.url = url
        fillPlayback()
        */
    }
}

class VideoPostCell : BaseSocialPostCell {
 
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    var avAsset: AVAsset?
    
    var avPlayerViewController: AVPlayerViewController? {
        didSet {
            guard
                let pvc = avPlayerViewController
            else {
                return
            }
            
            pvc.view.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(pvc.view, at: 0)
            pvc.view.topAnchor.constraint(equalTo: headerContainer.bottomAnchor).isActive = true
            pvc.view.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            pvc.view.bottomAnchor.constraint(equalTo: footerContainer.topAnchor).isActive = true
            pvc.view.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            pvc.view.backgroundColor = UIColor.yellow
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //setupPlayer()
        setupPlayerController()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Pause on scroll
        avPlayerViewController?.player?.pause()
        avPlayerViewController?.player = nil
    }
    
    override open func fill(wrapper: PostWrapper) {
        super.fill(wrapper: wrapper)
        
        guard
            let delegate = wrapper.cellDelegate,
            let videoUrl = wrapper.post.imageUrls?.first,
            let url = S3Folder.posts.downloadURL(cloudKey: videoUrl)
        else {
            return
        }
        
        let shouldPlay = delegate.shouldPlay(indexPath: indexPath)
        
        print2("VideoURL: \(videoUrl) shouldPlay: \(shouldPlay)")
        
        //loadAndPlayVideo(url: url)
        
        if shouldPlay {
            let player = AVPlayer(url: url)
            
            if avPlayerViewController == nil {
                avPlayerViewController = AVPlayerViewController()
            }
            
            avPlayerViewController?.player = player
            avPlayerViewController?.showsPlaybackControls = true
            avPlayerViewController?.player?.play()
        }
        else {
            if let pc = self.avPlayerViewController {
                pc.player?.pause()
                pc.player = nil
            }

            //show video thumbnail with play button on it.
        }
    }
    
    private func setupPlayerController() {
        avPlayerViewController = AVPlayerViewController()
    }
    
    /*
    private func setupPlayer() {
        // Create a new AVPlayer and AVPlayerLayer
        self.avPlayer = AVPlayer()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        
        // We want video controls so we need an AVPlayerViewController
        avPlayerViewController = AVPlayerViewController()
        avPlayerViewController?.player = avPlayer
    }
    */
    
    /*
    private func loadAndPlayVideo(url: URL) {
        // TODO: handle case when url is same as before --> just play
        
        print2("loadAndPlayVideo \(url)")
        
        avAsset?.cancelLoading()
        
        // Pause the existing video (if there is one)
        avPlayer?.pause()
        
        // Create a new AVAsset from the URL
        avAsset = AVAsset(url: url)
        
        avAsset?.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            guard let asset = self?.avAsset, asset.statusOfValue(forKey: "duration", error: nil) == .loaded else {
                return
            }
            
            let videoPlayerItem = AVPlayerItem(asset: asset)
            DispatchQueue.main.async {
                self?.avPlayer?.replaceCurrentItem(with: videoPlayerItem)
                self?.avPlayer?.play()
            }
        }
    }
    */
}

/*
class VideoPostCell2 : BaseSocialPostCell, VPKViewInCellProtocol {
    
    var videoView: VPKVideoView? {
        didSet {
            self.setupVideoViewConstraints()
            layoutIfNeeded()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        prepareForVideoReuse()
    }
    
    override func fill(indexPath: IndexPath, delegate: PostCellDelegate?, post: OrbisPost, winnerGroup: Group?, loserGroup: Group?, user: OrbisUser?, place: Place?) {
        super.fill(indexPath: indexPath, delegate: delegate, post: post, winnerGroup: winnerGroup, loserGroup: loserGroup, user: user, place: place)
    
        guard
            let delegate = delegate,
            let videoUrl = post.imageUrls?.first
            else {
                return
        }
        
        let url = S3Folder.posts.downloadKey(cloudKey: videoUrl)
        let model = VPKVideoType.remote(url: url, placeholderURLName: "")
        
        VPKVideoPlaybackBuilder.vpk_buildViewInCell(for: model, at: indexPath as NSIndexPath, with: ToolBarTheme.normal, completion: { [weak self] (videoView) in
            self?.videoView = videoView
            self?.layoutIfNeeded()
        })
    }
    
    private func setupVideoViewConstraints() {
        guard let safeView = videoView else { return }
        addSubview(safeView)

        safeView.snp.makeConstraints { (make) in
            make.left.top.equalTo(self).offset(20.0)
            make.right.bottom.equalTo(self).offset(-20.0)
            make.height.equalTo(250) //Ideally we would use an aspect ratio adjusted height based on data from json
        }
        
        safeView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        self.setNeedsDisplay()
    }
    
}
*/
