//
//  ChatViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import Photos

class ChatViewModel : OrbisViewModel {
    
    let userViewModel: UserViewModel!
    private var currentThread: ChatMessageWrapper!
    private(set) var messages = [ChatMessage]()
    private lazy var myUser: OrbisUser? = { return UserDefaultsRepository.instance().getMyUser() } ()
    private lazy var scheduler: SerialDispatchQueueScheduler = { return SerialDispatchQueueScheduler(qos: DispatchQoS.default) } ()
    
    // True in case coming from last messages
    let extendedMode: Bool

    let defaultSubject = PublishSubject<Any>()
    let tableOperationSubject = PublishSubject<TableOperation>()
    
    private var observingChildAdditions = false
    
    init(userViewModel: UserViewModel, currentThread: ChatMessageWrapper) {
        self.userViewModel = userViewModel
        self.currentThread = currentThread
        self.extendedMode = currentThread.message != nil
        super.init()
        loadChat(userViewModel: userViewModel)
    }
    
    private func loadChat(userViewModel: UserViewModel) {
        guard let ct = currentThread else { return }

        defaultSubject.onNext(OrbisAction.taskStarted)
        
        userViewModel.groupLoadedSubject
            .filter { value in return value }
            .flatMap { _ in
                return ChatDAO.loadChat(userId: ct.sender.uid, userId2: ct.receiver.uid)
            }
            .subscribe(onNext: { [weak self] msgs in
                print2("Loaded \(msgs.count) messages \(ct.sender.uid ?? "") \(ct.receiver.uid ?? "")")
                print2("Loaded \(msgs.count) messages \(ct.sender.username ?? "") \(ct.receiver.username ?? "")")
                guard let this = self else { return }
                
                // Visiting another profile
                if this.currentThread.message == nil {
                    if let first = msgs.first {
                        this.currentThread.message = first
                    }
                }
                
                this.messages = msgs
                this.observeChatAdditions()
                this.defaultSubject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)
    }
    
    private func observeChatAdditions() {
        guard
            let chatKey = currentThread.message?.chatKey,
            !observingChildAdditions
        else {
            print2("observeChatAdditions early return")
            return
        }
    
        observingChildAdditions = true
        
        ChatDAO.observeAdditionEvents(chatKey: chatKey, lastMsgKey: messages.last?.messageKey)
            .subscribeOn(scheduler)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] newMessage in
                guard let msg = newMessage else { return }
                self?.handleNewMessage(msg: msg)
            })
            .disposed(by: bag)
    }
    
    private func handleNewMessage(msg: ChatMessage) {
        print2("handleNewMessage \(msg.chatKey) - \(msg.messageKey)")
        
        if let index = messages.firstIndex(where: { m in return m.messageKey == msg.messageKey }) {
            messages[index] = msg
            tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index))
        }
        else {
            messages.append(msg)
            
            if messages.count == 1 {
                tableOperationSubject.onNext(TableOperation.ReloadOperation())
            }
            else {
                tableOperationSubject.onNext(
                    TableOperation.InsertOperation(
                        start: messages.count-1,
                        end: messages.count-1,
                        scroll: messageIsFromMe(msg: msg)
                    )
                )
            }
        }
    }
    
    func oppositeUser() -> OrbisUser? {
        guard let me = myUser else {
            return nil
        }
        return currentThread.oppositeUser(user: me)
    }
    
    func oppositeUserAndGroup() -> (OrbisUser, Group?)? {
        guard let me = myUser else {
            return nil
        }
        return currentThread.oppositeUserAndGroup(user: me)
    }
    
    func messageIsFromMe(msg: ChatMessage) -> Bool {
        return msg.senderId == myUser?.uid
    }
    
    func messageInfo(indexPath: IndexPath) -> (ChatMessage, OrbisUser, Group?, Cells) {
        return messageInfo(index: indexPath.row)
    }
    
    func messageInfo(index: Int) -> (ChatMessage, OrbisUser, Group?, Cells) {
        let msg = messages[index]
        let user: OrbisUser
        let group: Group?
        let type: Cells
        let hasImage = (msg.imageUrls?.count ?? 0) > 0
        
        if msg.senderId == currentThread.sender.uid {
            user = currentThread.sender
            group = currentThread.senderGroup
        }
        else {
            user = currentThread.receiver
            group = currentThread.receiverGroup
        }
        
        if messageIsFromMe(msg: msg) {
            type = hasImage ? Cells.rightChatImage : Cells.rightChatText
        }
        else {
            type = hasImage ? Cells.leftChatImage : Cells.leftChatText
        }
    
        return (msg, user, group, type)
    }

    func shouldDisplayDate(index: Int) -> Bool {
        if index == messages.count - 1 {
            return true
        }
    
        let m1 = messages[index]
        let m2 = messages[index+1]
        
        if m1.senderId != m2.senderId {
            return true
        }
        
        let d1 = m1.serverDate?.dateString()
        let d2 = m2.serverDate?.dateString()
        
        return d1 != d2
    }
    
    func saveMessage(text: String?, asset: PHAsset?) -> Bool {
        var imageUrls: [String]? = nil
        
        guard let me = myUser else {
            defaultSubject.onNext(Words.errorNoUserChat)
            return false
        }

        if let asset = asset {
            let fileExtension = "jpeg"
            let random = String.random(ofLength: 8)
            let cloudKey = S3Folder.chats.uploadKey(cloudKey: random, localFileType: fileExtension)
            imageUrls = ["\(random).\(fileExtension)"]
            S3Repository.instance().upload(imageAssets: [asset], keys: [cloudKey])
        }
        else {
            guard let t = text, !t.isEmpty, !t.isWhitespace else {
                defaultSubject.onNext(Words.textCannotBeEmpty)
                return false
            }
        }
        
        let chatKey: String
        let isNewChat: Bool
        
        if let parent = currentThread.message {
            chatKey = parent.chatKey
            isNewChat = false
        }
        else {
            guard let k = ChatDAO.getNewChatKey() else {
                defaultSubject.onNext(Words.errorGeneric)
                return false
            }
            chatKey = k
            isNewChat = true
        }
        
        guard let msgKey = ChatDAO.getNewMessageKey(chatKey: chatKey) else {
            defaultSubject.onNext(Words.errorGeneric)
            return false
        }
        
        let msg = ChatMessage(
            chatKey: chatKey,
            messageKey: msgKey,
            senderId: me.uid,
            receiverId: currentThread.oppositeUser(user: me).uid,
            text: text,
            imageUrls: imageUrls,
            openedByReceiver: false,
            welcomeMessage: false,
            serverTimestamp: nil)
    
        currentThread.message = msg
        observeChatAdditions()
        
        ChatDAO.saveMessage(msg: msg, isNewChat: isNewChat)
            .subscribeOn(scheduler)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { _ in
                print2("Message saved")
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
        
        return true
    }
    
    func group() -> Group? {
        return userViewModel.group
    }
}
