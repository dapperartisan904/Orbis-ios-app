//
//  SettingsViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 22/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class SettingsViewModel : OrbisViewModel {
    
    var user: OrbisUser! {
        didSet {
            loadMyGroups()
            loadAdminGroups()
            loadPlaces()
            loadPosts()
        }
    }
    
    var expandedSocialSections = Set<Int>()
    private var socialSectionItems = [[Any]]()
    private (set) var activeGroup: Group?
    private var loadingPostWrapper = false
    
    let reloadSectionSubject = PublishSubject<[Int]>()
    let tableOperationSubject = PublishSubject<TableOperation>()
    let loadPostWrapperTaskSubject = PublishSubject<OrbisAction>()
    let anySubject = PublishSubject<Any>()
    
    override init() {
        super.init()
        
        socialSectionItems.append([Group]())
        socialSectionItems.append([Group]())
        socialSectionItems.append([PlaceWrapper]())
        socialSectionItems.append([OrbisPost]())
        socialSectionItems.append([Group]())
        
        HelperRepository.instance().activeGroupSubject
            .subscribe(onNext: { [weak self] group in
                guard let this = self else { return }
                this.activeGroup = group.1
                this.reloadSectionSubject.onNext([2])
            })
            .disposed(by: bag)
        
        HelperRepository.instance().groupEditedSubject
            .subscribe(onNext: { [weak self] group in
                guard let this = self else {
                    return
                }
                
                print2("SettingsViewModel observed groupEditedSubject \(String(describing: group.name)) \(group.key ?? "")")
                
                [0, 1, 4].forEach { section in
                    guard let key = group.key else {
                        return
                    }
                    
                    var paths = [IndexPath]()
                    
                    if let index = this.indexOf(groupKey: key, inSection: section) {
                        this.socialSectionItems[section][index] = group
                        paths.append(IndexPath(row: index, section: section))
                        print2("SettingsViewModel observed groupEditedSubject propagate \(section) - \(index)")
                    }
                    
                    if !paths.isEmpty {
                        this.tableOperationSubject.onNext(TableOperation.UpdateOperation(indexPaths: paths))
                    }
                }
            }, onError: { error in
                print2("SettingsViewModel groupEditedSubject error")
                print2(error)
            })
            .disposed(by: bag)
        
        RolesViewModel.instance().roleByGroupChangedSubject
            .subscribe(onNext: { [weak self] groupKey in
                guard
                    let this = self,
                    let index = this.indexOf(groupKey: groupKey, inSection: 0)
                else {
                    return
                }
            
                if RolesViewModel.instance().memberStatus(groupKey: groupKey).0 == RoleStatus.inactive {
                    this.socialSectionItems[0].remove(at: index)
                    this.tableOperationSubject.onNext(TableOperation.DeleteOperation(index: index, section: 0))
                }
            })
            .disposed(by: bag)
    }
    
    func saveImage(image: UIImage) {
        let key = user.uid + "-" + Int.random(in: 0...1000).string
        S3Repository.instance().upload(
            image: image,
            key: S3Folder.users.uploadKey(cloudKey: key, localFileType: "jpeg"),
            completionBlock: { [weak self] in
                guard let this = self else { return }
                this.user.imageName = "\(key).jpeg"
                UserDAO.save(user: this.user)
                    .subscribe(onSuccess: { _ in }, onError: { error in print2(error) })
                    .disposed(by: this.bag)
            })
    }
    
    func numberOfItemsOfSocialSection(section: Int) -> Int {
        if expandedSocialSections.contains(section) {
            return socialSectionItems.safeGet(index: section)?.count ?? 0
        }
        else {
            return 0
        }
    }
    
    func getItem(section: Int, row: Int) -> Any? {
        return socialSectionItems.safeGet(index: section)?.safeGet(index: row)
    }
    
    func isExpanded(section: Int) -> Bool {
        return expandedSocialSections.contains(section)
    }
    
    func indexOf(post: OrbisPost) -> Int? {
        return socialSectionItems[3].firstIndex(where: { (item: Any) -> Bool in
            return post.postKey == (item as? OrbisPost)?.postKey
        })
    }
    
    func indexOf(groupKey: String, inSection section: Int) -> Int? {
        return socialSectionItems[section].firstIndex(where: { (item: Any) -> Bool in
            return groupKey == (item as? Group)?.key
        })
    }
    
    func indexOf(placeKey: String, inSection section: Int) -> Int? {
        return socialSectionItems[2].firstIndex(where: { (item: Any) -> Bool in
            return placeKey == (item as? PlaceWrapper)?.place.key
        })
    }
    
    func loadMyGroups() {
        GroupDAO.loadGroupsOfUser(userId: user.uid, requiredRole: Roles.member)
            .subscribe(onSuccess: { [weak self] groups in
                self?.socialSectionItems[0] = groups
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func loadAdminGroups() {
        GroupDAO.loadGroupsOfUser(userId: user.uid, requiredRole: Roles.administrator)
            .subscribe(onSuccess: { [weak self] groups in
                self?.socialSectionItems[1] = groups
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func loadPlaces() {
        PlaceDAO.loadPlaces(followedBy: user.uid)
            .flatMap({ (places: [String: Place]) -> Single<[PlaceWrapper]> in
                return PlaceWrapperDAO.load(placeKeys: Array(places.keys), excludeDeleted: true)
            })
            .subscribe(onSuccess: { [weak self] wrappers in
                self?.socialSectionItems[2] = wrappers.sorted(by: {(p0, p1) in
                    return p0.place.name.lowercased().compare(p1.place.name.lowercased()) == ComparisonResult.orderedAscending})
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func loadPosts() {
        PostDAO.loadPostsByUser(userKey: user.uid, types: [PostType.text, PostType.images, PostType.video])
            .subscribe(onSuccess: { [weak self] posts in
                print2("loadPostsByUser [3] count: \(posts.count)")
                self?.socialSectionItems[3] = posts
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }

    func optionSelected(option: SettingsPostMenuOptions, post: OrbisPost) {
        switch option {
        case .deletePost:
            PostDAO.delete(post: post)
                .subscribe(onSuccess: { [weak self] _ in
                    guard
                        let this = self,
                        let index = this.indexOf(post: post)
                    else {
                        return
                    }
                    
                    this.socialSectionItems[3].remove(at: index)
                    this.tableOperationSubject.onNext(TableOperation.DeleteOperation(index: index, section: 3))
                    
                }, onError: { error in
                    print2(error)
                })
                .disposed(by: bag)
        }
    }
    
    func loadPostWrapper(post: OrbisPost) {
        if loadingPostWrapper {
            return
        }
        
        loadingPostWrapper = true
        loadPostWrapperTaskSubject.onNext(OrbisAction.taskStarted)
        
        PostDAO.loadWrapper(post: post, user: user, activeGroup: activeGroup)
            .subscribe(onSuccess: { [weak self] wrapper in
                guard let wrapper = wrapper else {
                    self?.onLoadPostWrapperError()
                    return
                }
                
                self?.loadingPostWrapper = false
                self?.loadPostWrapperTaskSubject.onNext(OrbisAction.taskFinished)
                self?.anySubject.onNext(Navigation.comments(postWrapper: wrapper))
            }, onError: { [weak self] error in
                print2(error)
                self?.onLoadPostWrapperError()
            })
            .disposed(by: bag)
    }
    
    private func onLoadPostWrapperError() {
        loadingPostWrapper = false
        loadPostWrapperTaskSubject.onNext(OrbisAction.taskFailed)
        anySubject.onNext(OrbisErrors.generic)
    }
    
    func save(unit: OrbisUnit) {
        UserDAO.saveUnit(userId: user.uid, value: unit)
            .subscribe(onSuccess: { _ in }, onError: { error in })
            .disposed(by: bag)
    }
    
    func save(notificationsEnabled: Bool) {
        UserDAO.savePushNotificationsEnabled(userId: user.uid, value: notificationsEnabled)
            .subscribe(onSuccess: { _ in }, onError: { error in })
            .disposed(by: bag)
    }
}
