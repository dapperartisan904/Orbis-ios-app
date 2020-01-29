//
//  ChatViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import RxKeyboard

class ChatViewController : OrbisViewController {

    @IBOutlet weak var userImageView: RoundedImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var activeLabel: UILabel!
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var topLineView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var photoButton: UIImageView!
    @IBOutlet weak var sendButton: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var chatViewModel: ChatViewModel!
    private var initialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print2("ChatViewModel viewDidLoad")
        
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
                this.handleNavigation(navigation: .chatImageSelector(chatViewModel: this.chatViewModel))
            })
            .disposed(by: bag)
        
        sendButton.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.saveMessage()
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
        
        if let vm = chatViewModel, !vm.extendedMode {
            initialize()
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        print2("ChatViewModel didMoveToParent")
        
        if let vm = chatViewModel, vm.extendedMode {
            initialize()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatViewModel.userViewModel.showingChatSubject.onNext(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatViewModel.userViewModel.showingChatSubject.onNext(false)
    }
    
    // TODO KINE: test automatic scroll on iPad (improvements needed)
    override func shoulScrollToBottomOnAddition() -> Bool {
        return true
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    // Refers to load task
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    // Refers to load task
    override func onTaskFinished() {
        tableView.reloadData()
        indicatorView.stopAnimating()
        tableView.scrollToBottom(animated: false)
    }
    
    // Refers to load task
    override func onTaskFailed() {
        indicatorView.stopAnimating()
    }
    
    private func saveMessage() {
        if chatViewModel.saveMessage(text: textView.text, asset: nil) {
            textView.text = ""
            updateBottomViews()
        }
    }
    
    private func initialize() {
        if initialized {
            return
        }
        
        initialized = true
        
        tableView.allowsSelection = false
        //tableView.rowHeight = 200.0
        tableView.separatorStyle = .none
        tableView.register(cell: Cells.leftChatText)
        tableView.register(cell: Cells.leftChatImage)
        tableView.register(cell: Cells.rightChatText)
        tableView.register(cell: Cells.rightChatImage)
        tableView.dataSource = self
        tableView.delegate = self
        
        if chatViewModel.extendedMode {
            closeButton.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    guard let this = self else { return }
                    this.willMove(toParent: nil)
                    this.view.removeFromSuperview()
                    this.removeFromParent()
                })
                .disposed(by: bag)
            
            if let (user, group) = chatViewModel.oppositeUserAndGroup() {
                userImageView.loadUserImage(image: nil, user: user, activeGroup: group, width: 2.0)
                userLabel.text = user.username
                
                if let date = user.activeServerDate {
                    let now = Date()
                    let days = now.daysSince(date).floor.int
                    let hours = now.hoursSince(date).floor.int
                    let minutes = now.minutesSince(date).floor.int
                    var str = Words.active.localized + " "
                    
                    if days > 0 {
                        str += "\(days) \(Words.days.localized)"
                    }
                    else if hours > 0 {
                        str += "\(hours) \(Words.hours.localized)"
                    }
                    else {
                        str += "\(minutes) \(Words.minutes.localized)"
                    }
                    
                    str += " " + Words.ago.localized
                    activeLabel.text = str
                }
                else {
                    activeLabel.text = nil
                }

                [userImageView, userLabel].forEach { v in
                    v?.rx.tapGesture()
                        .when(.recognized)
                        .subscribe(onNext: { [weak self] _ in
                            self?.handleNavigation(navigation: Navigation.user(user: user))
                        })
                        .disposed(by: bag)
                }
            }
        }
        else {
            closeButton.isHidden = true
            userImageView.isHidden = true
            userLabel.isHidden = true
            activeLabel.isHidden = true
            topLineView.isHidden = true
            tableTopConstraint.constant = 0.0
        }
        
        chatViewModel.tableOperationSubject
            .subscribe(onNext: { [weak self] op in
                guard let this = self else { return }
                this.handleTableOperation(operation: op, tableView: this.tableView)
            })
            .disposed(by: bag)
        
        observeDefaultSubject(subject: chatViewModel.defaultSubject)
    }
    
    private func updateBottomViews() {
        placeholderLabel.isHidden = !textView.isBlank
        photoButton.isHidden = !textView.isBlank
        sendButton.isHidden = textView.isBlank
    }
}

extension ChatViewController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatViewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (msg, user, group, type) = chatViewModel.messageInfo(indexPath: indexPath)
        let cell = tableView.dequeueReusableCell(withCellType: type, for: indexPath) as! BaseChatCell
        
        if indexPath.row == 3 {
            print2("aki!!!")
        }
        
        cell.delegate = self
        cell.dateLabel.textColor = UIColor(rgba: "#9e9e9e")
        cell.timeLabel.text = msg.serverDate?.timeString(ofStyle: .short)

        if chatViewModel.shouldDisplayDate(index: indexPath.row) {
            cell.bottomConstraint.constant = 0.0
            cell.dateLabel.isHidden = false
            cell.dateLabel.text = msg.serverDate?.dateString(ofStyle: .short)
        }
        else {
            cell.bottomConstraint.constant = -20.0
            cell.dateLabel.isHidden = true
        }
        
        // Sent by other user
        if type == Cells.leftChatText || type == Cells.leftChatImage {
            cell.timeLabel.textColor = UIColor(rgba: "#AAAAAA")
            cell.userImageView.loadUserImage(image: nil, user: user, activeGroup: group, width: 2.0)
            cell.baloonImageView.backgroundColor = UIColor(rgba: "#EEEEEE")
        }
        // Sent by me
        else {
            cell.timeLabel.textColor = UIColor(rgba: "#EEEEEE")
            cell.userImageView.isHidden = true
            cell.baloonImageView.backgroundColor = groupSolidColor(group: group, defaultColor: UIColor.red)
        }
        
        if type == Cells.leftChatText || type == Cells.rightChatText {
            let textCell = cell as! ChatTextCell
            
            if type == Cells.leftChatText {
                textCell.msgLabel.textColor = UIColor.darkText
            }
            else {
                textCell.msgLabel.textColor = textColor(colorIndex: group?.colorIndex)
            }
            
            textCell.msgLabel.text = msg.text
        }
        else {
            let imageCell = cell as! ChatImageCell
            imageCell.loadImage(msg: msg)
        }
        
        return cell
    }
    
}

extension ChatViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }

}

extension ChatViewController : UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        updateBottomViews()
    }
    
}

extension ChatViewController: KeyboardToolbarDelegate {
    
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, tappedIn toolbar: KeyboardToolbar) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }
    
}

extension ChatViewController : ChatCellDelegate {
    
    func imageClick(cell: UITableViewCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        handleNavigation(navigation: .chatGallery(msg: chatViewModel.messages[indexPath.row]))
    }
    
}
