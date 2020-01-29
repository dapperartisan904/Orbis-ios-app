//
//  LastMessagesViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 26/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class LastMessagesViewController : OrbisViewController, UserChildController {
    
    var userViewModel: UserViewModel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    private lazy var lmViewModel: LastMessagesViewModel = { [unowned self] in
        return LastMessagesViewModel(userViewModel: userViewModel)
    }()

    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = true
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.rowHeight = 80.0
        tableView.hideUndesiredSeparators()
        tableView.register(cell: Cells.lastMessage)
        tableView.dataSource = self
        tableView.delegate = self
        
        observeDefaultSubject(subject: lmViewModel.defaultSubject)
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFinished() {
        tableView.reloadData()
        indicatorView.stopAnimating()
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
    }
}

extension LastMessagesViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lmViewModel.filteredLastMessage.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.lastMessage, for: indexPath) as! LastMessageCell
        let wrapper = lmViewModel.filteredLastMessage[indexPath.row]
        var user: OrbisUser
        var group: Group?
        
        if lmViewModel.messageIsFromMe(wrapper: wrapper) {
            user = wrapper.receiver
            group = wrapper.receiverGroup
        }
        else {
            user = wrapper.sender
            group = wrapper.senderGroup
        }
        
        cell.selectionStyle = .none
        cell.userImageView.loadUserImage(image: nil, user: user, activeGroup: group, width: 2.0)
        cell.userLabel.text = user.username
        cell.dateLabel.text = wrapper.message!.serverDate?.dateTimeString(ofStyle: .short)
        
        if let _ = wrapper.message!.imageUrls {
            cell.msgLabel.isHidden = true
            cell.photoLabel.isHidden = false
            cell.photoImageView.isHidden = false
            cell.photoLabel.text = Words.photo.localized
            cell.photoImageView.image = UIImage(named: "baseline_photo_camera_white_48pt")?.template
        }
        else {
            cell.msgLabel.text = wrapper.message!.text
            cell.msgLabel.isHidden = false
            cell.photoLabel.isHidden = true
            cell.photoImageView.isHidden = true
        }
        
        return cell
    }
    
}

extension LastMessagesViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print2("LastMessagesViewController didSelectRowAt \(indexPath.row)")
        let wrapper = lmViewModel.filteredLastMessage[indexPath.row]
        let viewModel = ChatViewModel(userViewModel: userViewModel, currentThread: wrapper)
        handleNavigation(navigation: Navigation.chat(viewModel: viewModel))
    }
    
}
