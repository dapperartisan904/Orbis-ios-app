//
//  CommentsViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import Photos

class CommentsViewModel : BasePostsViewModel {

    let post: OrbisPost
    let defaultSubject = PublishSubject<Any>()
    private(set) var selectedThread: String?
    
    private var comments = [OrbisComment]()
    private var groups = [String : Group]()
    private var users = [String : OrbisUser]()
    private var counters = [String : PostCounter]()
    
    init(wrapper: PostWrapper) {
        self.post = wrapper.post
        super.init()
        setData(wrapper: wrapper)
        loadComments()
    }
    
    func onViewControllerReady() {
        
    }
    
    private func loadComments() {
        CommentsDAO.loadComments(postKey: post.postKey)
            .subscribe(onSuccess: { [weak self] data in
                guard let this = self else { return }

                this.comments = data.0
                this.groups = data.1
                this.users = data.2
                this.counters = data.3
                this.onFirstChunkLoaded()
                
                print2("[Comments] count: \(this.comments.count)")
                
            }, onError: { [weak self] error in
                print2(error)
                self?.defaultSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)
    }
    
    private func observeCommentAdditions() {
        let serverTimestamp = (comments.map { $0.serverDate?.timeIntervalSince1970 ?? 0 }.max() ?? 0)
            .makeCompatibleWithAndroid()
    
        CommentsDAO.observeCommentAdditions(postKey: post.postKey, serverTimestamp: serverTimestamp)
            .subscribe(onNext: { [weak self] comment in
                guard
                    let this = self,
                    let comment = comment
                else {
                    return
                }

                if let index = this.comments.firstIndex(where: { $0.commentKey == comment.commentKey }) {
                    this.comments[index] = comment
                    this.tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index+1))
                }
                else {
                    this.insertComment(comment: comment, isMine: false)
                }
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    private func observeCounterChanges() {
        CountersDAO.observeCommentsCounterChanges(post: post)
            .subscribe(onNext: { [weak self] data in
                let commentKey = data.0
                
                guard
                    let this = self,
                    let counter = data.1,
                    let indexPath = this.indexPath(commentKey: commentKey),
                    counter.likesCount != this.counters[commentKey]?.likesCount
                else {
                    return
                }
            
                this.counters[commentKey] = counter
                this.tableOperationSubject.onNext(TableOperation.UpdateOperation(index: indexPath.row))
            }, onError: {
                error in print2(error)
            })
            .disposed(by: bag)
    }
    
    func saveComment(text: String?, asset: PHAsset?) -> Bool {
        var imageUrls: [String]? = nil
        
        guard let user = UserDefaultsRepository.instance().getMyUser() else {
            defaultSubject.onNext(Words.errorNoUserComment)
            return false
        }
        
        guard let group = UserDefaultsRepository.instance().getActiveGroup() else {
            defaultSubject.onNext(Words.errorNoActiveGroupComment)
            return false
        }
        
        guard let commentKey = CommentsDAO.newKey() else {
            defaultSubject.onNext(Words.errorGeneric)
            return false
        }
        
        if let asset = asset {
            let fileExtension = "jpeg"
            let random = String.random(ofLength: 8)
            let cloudKey = S3Folder.posts.uploadKey(cloudKey: random, localFileType: fileExtension)
            imageUrls = ["\(random).\(fileExtension)"]
            S3Repository.instance().upload(imageAssets: [asset], keys: [cloudKey])
        }
        else {
            guard let text = text, !text.isEmpty, !text.isWhitespace else {
                defaultSubject.onNext(Words.textCannotBeEmpty)
                return false
            }
        }
       
        if !groups.has(key: group.key!) {
            groups[group.key!] = group
        }
        
        if !users.has(key: user.uid) {
            users[user.uid] = user
        }

        counters[commentKey] = PostCounter(commentsCount: 0, likesCount: 0, serverDate: nil)
        
        let comment = OrbisComment(
            userId: user.uid,
            postKey: post.postKey,
            commentKey: commentKey,
            message: text ?? "",
            parentCommentKey: selectedThread ?? commentKey,
            groupKey: group.key,
            imageUrls: imageUrls,
            serverTimestamp: nil)
        
        insertComment(comment: comment, isMine: true)
        
        CommentsDAO.saveComment(post: post, comment: comment)
            .subscribe(onSuccess: { _ in }, onError: { error in })
            .disposed(by: bag)

        return true
    }
    
    private func insertComment(comment: OrbisComment, isMine: Bool) {
        let groupObservable: Single<Group?>
        let userObservable: Single<OrbisUser?>
        
        if let k = comment.groupKey {
            if groups.has(key: k) {
                groupObservable = Single.just(nil)
            }
            else {
                groupObservable = GroupDAO.findByKey(groupKey: k)
            }
        }
        else {
            groupObservable = Single.just(nil)
        }
        
        if users.has(key: comment.userId) {
            userObservable = Single.just(nil)
        }
        else {
            userObservable = UserDAO.load(userId: comment.userId)
        }
        
        groupObservable
            .flatMap { [weak self] (group : Group?) -> Single<OrbisUser?> in
                if let g = group {
                    self?.groups[g.key!] = g
                }
                return userObservable
            }
            .subscribe(onSuccess: { [weak self] user in
                if let u = user {
                    self?.users[u.uid] = user
                }
                self?.onNewCommentDataAvailable(comment: comment, isMine: isMine)
            })
            .disposed(by: bag)
    }
    
    private func onNewCommentDataAvailable(comment: OrbisComment, isMine: Bool) {
        let index: Int
        if comment.isMainThread() {
            index = comments.count
        }
        else {
            index = comments.firstIndex(where: { otherComment in
                guard let pk = otherComment.parentCommentKey else {
                    return false
                }
                return pk > comment.parentCommentKey! }) ?? comments.count
        }
        
        comments.insert(comment, at: index)
        tableOperationSubject.onNext(TableOperation.InsertOperation(start: index+1, end: index+1, scroll: isMine))
    }
    
    func commentData(index: Int) -> (OrbisComment, Group?, OrbisUser?, PostCounter?) {
        let comment = comments[index - 1]
        return (comment, groups[comment.groupKey ?? ""], users[comment.userId], counters[comment.commentKey])
    }
    
    func threadSelected(indexPath: IndexPath) {
        let comment = commentData(index: indexPath.row).0
        if comment.commentKey == selectedThread {
            selectedThread = nil
        }
        else {
            selectedThread = comment.commentKey
        }
        tableOperationSubject.onNext(TableOperation.UpdateOperation(index: indexPath.row))
    }
    
    func isSelectedThread(comment: OrbisComment) -> Bool {
        return comment.commentKey == selectedThread
    }
    
    func isCommentWithImage(index: Int) -> Bool {
        return commentData(index: index).0.imageUrls?.first != nil
    }
    
    func indexPath(commentKey: String) -> IndexPath? {
        guard let index = comments.firstIndex(where: { $0.commentKey == commentKey }) else {
            return nil
        }
        return (index + 1).toIndexPath()
    }
    
    override func numberOfItems(debug: Bool = false) -> Int {
        return super.numberOfItems(debug: debug) + comments.count
    }
    
    override func onFirstChunkLoaded() {
        // TODO KINE onFirstChunkLoaded: not sure if must call super
        observeCommentAdditions()
        observeCounterChanges()
        defaultSubject.onNext(OrbisAction.taskFinished)
    }
}

extension CommentsViewModel : PostsViewModelContract {
    func placedOnHome() -> Bool {
        return false
    }
    
    func radarTab() -> RadarTab? {
        return nil
    }
    
    func loadNextChunk() {
        // Do nothing
    }
    
}
