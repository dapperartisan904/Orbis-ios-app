//
//  CommentsViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxKeyboard

class CommentsViewController : BasePostsViewController<CommentsViewModel>, UITextViewDelegate {

    // Workaround because cannot assign outlet
    @IBOutlet weak var cardView2: CardView!
    @IBOutlet weak var toolbar: DefaultToolbar!
    @IBOutlet weak var postContainer: UIView!
    @IBOutlet weak var photoButton: UIImageView!
    @IBOutlet weak var sendButton: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    var commentsViewModel: CommentsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.delegate = self

        placeholderLabel.text = Words.writeMessageHere.localized
        
        let kt = KeyboardToolbar()
        kt.toolBarDelegate = self
        kt.setup(leftButtons: [], rightButtons: [.done])
        textView.inputAccessoryView = kt
        textView.text = ""
        textView.delegate = self
        
        photoButton.image = UIImage(named: "baseline_photo_camera_white_48pt")?
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(UIEdgeInsets(inset: -8))
        
        sendButton.image = UIImage(named: "round_send_black_48pt")?
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(UIEdgeInsets(inset: -8))
        
        photoButton.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.handleNavigation(navigation: .commentImageSelector(commentsViewModel: this.commentsViewModel))
            })
            .disposed(by: bag)
        
        sendButton.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                if this.commentsViewModel.saveComment(text: this.textView.text, asset: nil) {
                    this.textView.text = ""
                    this.updateBottomViews()
                }
            })
            .disposed(by: bag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { keyboardVisibleHeight in
                if keyboardVisibleHeight == 0 {
                    self.bottomConstraint.constant = keyboardVisibleHeight
                }
                else {
                    self.bottomConstraint.constant = keyboardVisibleHeight
                }
            })
            .disposed(by: bag)
        
        updateBottomViews()

        
        postsViewModel = commentsViewModel
        postsDelegate = CommentsTableDelegate(viewModel: postsViewModel)
        postsDataSource = CommentsTableDataSource(
            viewModel: postsViewModel,
            cellDelegate: self,
            activeGroup: UserDefaultsRepository.instance().getActiveGroup())
        
        configPostsTableView(container: postContainer)
        observePostsViewModel()
        observeLikesViewModel()
        observeDefaultSubject(subject: commentsViewModel.defaultSubject)
    }
    
    override func configPostsTableView(container: UIView) {
        super.configPostsTableView(container: container)
        tableView.register(cell: Cells.comment)
        tableView.backgroundView?.backgroundColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
    }
    
    // Refers to load comments task
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    // Refers to load comments task
    override func onTaskFinished() {
        tableView.reloadData()
        indicatorView.stopAnimating()
        tableView.scrollToBottom(animated: false)
    }
    
    // Refers to load comments task
    override func onTaskFailed() {
        indicatorView.stopAnimating()
    }
    
    override func processMyLikeChange(likeType: LikeType, likeInfo: LikeInfo) {
        switch likeType {
        case .post:
            super.processMyLikeChange(likeType: likeType, likeInfo: likeInfo)
        case .comment:
            if let indexPath = commentsViewModel.indexPath(commentKey: likeInfo.mainKey) {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        case .postImage:
            break
        }
    }

    override func mainGroupClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        
        if indexPath.row == 0 {
            super.mainGroupClick(cell: cell)
        }
        else if let group = commentsViewModel.commentData(index: indexPath.row).1 {
            handleNavigation(navigation: Navigation.group(group: group))
        }
    }
    
    override func likeClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }

        if indexPath.row == 0 {
            super.likeClick(cell: cell)
        }
        else {
            if UserDefaultsRepository.instance().hasMyUser() {
                let comment = commentsViewModel.commentData(index: indexPath.row).0
                
                guard let postKey = commentsViewModel.post.postKey else {
                    print2("Error liking: postKey is nil")
                    return
                }
                
                likesViewModel.toggleLike(likeType: .comment, mainKey: comment.commentKey, postKey: postKey, receiverId: comment.userId, superKey: postKey)
            }
            else {
                showOkAlert(title: Words.error, msg: Words.errorNoUserLikeComment)
            }
        }
    }
    
    override func userClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        
        if indexPath.row == 0 {
            super.userClick(cell: cell)
        }
        else if let user = commentsViewModel.commentData(index: indexPath.row).2 {
            handleNavigation(navigation: Navigation.user(user: user))
        }
    }
    
    override func commentClick(cell: UITableViewCell?) {
        // Do nothing
    }

    private func updateBottomViews() {
        placeholderLabel.isHidden = !textView.isBlank
        photoButton.isHidden = !textView.isBlank
        sendButton.isHidden = textView.isBlank
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateBottomViews()
    }
}

extension CommentsViewController : CommentCellDelegate {

    func replyClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        
        commentsViewModel.threadSelected(indexPath: indexPath)
    }

}


extension CommentsViewController: KeyboardToolbarDelegate {
    
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, tappedIn toolbar: KeyboardToolbar) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }
    
}
