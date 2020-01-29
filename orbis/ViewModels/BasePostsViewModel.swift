//
//  BasePostsViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 04/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import Firebase
import FirebaseDatabase
import GoogleMobileAds
import SwifterSwift

/*
    Methods that should be implemented on concrete classes
*/
protocol PostsViewModelContract {
    func onViewControllerReady()
    func loadNextChunk()
    func placedOnHome() -> Bool
    func radarTab() -> RadarTab?
}

class BasePostsViewModel : OrbisViewModel {
    
    private var posts = [OrbisPost]()
    private var originalPosts = [OrbisPost]()
    private var groups = [String : Group]()
    private var places = [String : Place]()
    private var users = [String : OrbisUser]()
    private var counters = [String : PostCounter]()
    private var adMobs = [GADUnifiedNativeAd]()
    private var postsBeingLoaded = Set<String>()
    private var maxScrollPosition = 0
    
    private(set) var firstChunk = true
    
    private(set) var isLoading = true {
        didSet {
            HomeViewModel.instance().updateRadarProgressBar(isLoading: isLoading)
        }
    }

    let videoReuseIdentifiers: [String] = Array(0...9).lazy.map { "videoCell_\($0)" }

    let tableOperationSubject = PublishSubject<TableOperation>()
    let baseSubject = PublishSubject<Any>()
    
    //private var nativeAds = [GADUnifiedNativeAd]()
    
    override init() {
        super.init()
        observeLogout()
    }
    
    func set(isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    func getPost(indexPath: IndexPath, searchInEventGroup: Bool = true) -> OrbisPost {
        var post = getPost(cellPosition: indexPath.row)
        if searchInEventGroup {
            if let type = post.typeEnum(), type == .eventGroup {
                post = post.eventGroup![indexPath.section]
            }
        }
        return post
    }
    
    func getPost(cellPosition: Int) -> OrbisPost {
        if adMobsEnabled() {
            let postPosition = cellPosition - min(cellPosition / adsFrequency, adMobs.count)
            return posts[postPosition]
        }
        else {
            return posts[cellPosition]
        }
    }
    
    func getWinnerGroup(post: OrbisPost) -> Group? {
        guard let k = post.winnerGroupKey else {
            return nil
        }
        return groups[k]
    }
    
    func getLoserGroup(post: OrbisPost) -> Group? {
        guard let k = post.loserGroupKey else {
            return nil
        }
        return groups[k]
    }
    
    func getDominantGroup(post: OrbisPost) -> Group? {
        guard
            let place = getPlace(post: post),
            let groupKey = place.dominantGroupKey
        else {
            return nil
        }
        return groups[groupKey]
    }
    
    func getUser(post: OrbisPost) -> OrbisUser? {
        guard let k = post.userKey else {
            return nil
        }
        return users[k]
    }
    
    func getPlace(post: OrbisPost) -> Place? {
        guard let k = post.placeKey else {
            return nil
        }
        return places[k]
    }
    
    func getPlaceWrapper(indexPath: IndexPath) -> PlaceWrapper? {
        let post = getPost(indexPath: indexPath)
        
        guard
            let place = getPlace(post: post)
        else {
            return nil
        }
        
        return PlaceWrapper(place: place, group: getDominantGroup(post: post))
    }
    
    func getCounter(post: OrbisPost) -> PostCounter? {
        return counters[post.postKey]
    }
    
    func getPostWrapper(indexPath: IndexPath, activeGroup: Group?, isLiking: Bool, cellDelegate: PostCellDelegate?) -> PostWrapper {
        let post = getPost(indexPath: indexPath)
        return PostWrapper(
            post: post,
            winnerGroup: getWinnerGroup(post: post),
            loserGroup: getLoserGroup(post: post),
            activeGroup: activeGroup,
            user: getUser(post: post),
            place: getPlace(post: post),
            counter: getCounter(post: post),
            isLiking: isLiking,
            indexPath: indexPath,
            cellDelegate: cellDelegate)
    }
    
    func getAdMob(indexPath: IndexPath) -> GADUnifiedNativeAd? {
        let adPosition = (indexPath.row / adsFrequency) - 1
        return adMobs[adPosition]
    }
    
    func indexOf(postKey : String?) -> Int? {
        guard
            let postKey = postKey,
            let indexOnPosts = posts.firstIndex(where: {
                if let type = $0.typeEnum(), type == .eventGroup {
                    if let _ = $0.eventGroup!.firstIndex(where: { $0.postKey == postKey }) { return true }
                    else { return false }
                }
                return $0.postKey == postKey
            })
        else {
            return nil
        }
        
        if adMobsEnabled() {
            return indexOnPosts + adsCountBeforePosition(position: indexOnPosts)
        }
        else {
            return indexOnPosts
        }
    }
    
    func tableIndexOf(postKey: String?) -> Int? {
        guard let indexOnPostsList = indexOf(postKey: postKey) else {
            return nil
        }
    
        if adMobsEnabled() {
            return indexOnPostsList + adsCountBeforePosition(position: indexOnPostsList)
        }
        else {
            return indexOnPostsList
        }
    }

    func numberOfItems(debug: Bool = false) -> Int {
        if adMobsEnabled() {
            let count = posts.count + min(posts.count / adsFrequency, adMobs.count)
            
            if debug {
                print2("Posts count: \(posts.count)")
                print2("Ads count: \(adMobs.count)")
                print2("Ads frequency: \(adsFrequency)")
                print2("posts.count / adsFrequency: \(posts.count / adsFrequency)")
                print2("min(posts.count / adsFrequency, adMobs.count): \(min(posts.count / adsFrequency, adMobs.count))")
            }
            
            return count
        }
        else {
            return posts.count
        }
    }
    
    // To be overriden
    func onLogout() { }
    
    // Should not be overriden
    func clearData() {
        posts.removeAll()
        originalPosts.removeAll()
        groups.removeAll()
        places.removeAll()
        users.removeAll()
        counters.removeAll()
    }
    
    // Useful for comments
    func setData(wrapper: PostWrapper) {
        posts = [wrapper.post]
        
        if let g = wrapper.winnerGroup {
            groups[g.key!] = g
        }
        
        if let g = wrapper.loserGroup {
            groups[g.key!] = g
        }
        
        if let p = wrapper.place {
            places[p.key] = p
        }
        
        if let u = wrapper.user {
            users[u.uid] = u
        }
        
        if let c = wrapper.counter {
            counters[wrapper.post.postKey] = c
        }
    }
    
    func sortFunction(p0: OrbisPost, p1: OrbisPost) -> Bool {
        return p0.serverTimestamp > p1.serverTimestamp
    }

    func shouldObservePostChildAdditions() -> Bool {
        return true
    }
    
    func adMobsEnabled() -> Bool {
        return false
    }
    
    // Should be used only to load individual posts
    func loadPost(postKey: String) {
        if HiddenPostViewModel.instance().isHidden(postKey: postKey) {
            return
        }
        
        PostDAO.load(postKey: postKey)
            .filter { post in post != nil }.map { $0! }
            .filter { !BannedUsersViewModel.instance().isBanned(userId: $0.userKey) }
            .flatMap { [weak self] (post : OrbisPost) -> Maybe<Bool> in
                guard let this = self else {
                    return Maybe.just(false)
                }
                return this.loadDataObservable(postsLoaded: [post]).asMaybe()
            }
            .subscribe(onSuccess: {  _ in
                
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func loadDataObservable(postsLoaded: [OrbisPost]) -> Single<Bool> {
        print2("[loadDataObservable] begin hasCode: \(hashValue)")
        
        // TODO KINE: see postShouldBeDisplayed on Android
        
        let hpvm = HiddenPostViewModel.instance()
        let buvm = BannedUsersViewModel.instance()
        
        var newPosts = postsLoaded.withoutDuplicates()
            .filter { post in
                return !posts.contains(where: { otherPost in otherPost == post }) &&
                    !hpvm.isHidden(postKey: post.postKey) &&
                    !buvm.isBanned(userId: post.userKey)
            }
    
        let newPostKeys = newPosts.map { $0.postKey! }
        print2("[loadDataObservable] newPostKeys count: \(newPostKeys.count)")
        
        let newPlaceKeys = newPosts.filter { post in
            guard let placeKey = post.placeKey else { return false }
            return !places.has(key: placeKey)
        }.map { post in
            return post.placeKey!
        }.withoutDuplicates()
    
        return PlaceDAO
            .loadPlaceByKeys(placeKeys: newPlaceKeys)
            .flatMap { [weak self] (newPlaces : [String : Place]) -> Single<[String : Group]> in
                print2("[loadDataObservable] step 1")
                
                guard let this = self else {
                    return Single.just([String : Group]())
                }
                
                this.places.merge(newPlaces, uniquingKeysWith: { p0, p1 in return p0 })
                
                let keys1 = newPosts
                    .filter { post in return post.winnerGroupKey != nil }
                    .map { post in return post.winnerGroupKey! }
                
                let keys2 = newPosts
                    .filter { post in return post.loserGroupKey != nil }
                    .map { post in return post.loserGroupKey! }

                let keys3 = newPlaces.values
                    .filter { place in return place.dominantGroupKey != nil }
                    .map { place in return place.dominantGroupKey! }
                
                let keys = (keys1 + keys2 + keys3)
                    .withoutDuplicates()
                    .filter { key in return !this.groups.has(key: key) }
                
                return GroupDAO.loadGrousAsDictionary(groupKeys: keys)
            }
            .flatMap { [weak self] (newGroups : [String : Group]) -> Single<[String : OrbisUser]> in
                print2("[loadDataObservable] step 2")
                
                guard let this = self else {
                    return Single.just([String : OrbisUser]())
                }
            
                this.groups.merge(newGroups, uniquingKeysWith: { g0, g1 in return g0 })
                
                // TODO KINE: load notifications before users
                
                let keys1 = newPosts
                    .filter { post in return post.userKey != nil }
                    .map { post in return post.userKey! }

                let keys = keys1
                    .withoutDuplicates()
                    .filter { key in return !this.users.has(key: key) }
                
                print2("[loadDataObservable] step 2 userKeys count: \(keys.count)")
                
                return UserDAO.loadUsersByIds(userIds: keys)
            }
            .flatMap { [weak self] (newUsers : [String : OrbisUser]) -> Single<[String : PostCounter]> in
                print2("[loadDataObservable] step 3")
                
                guard let this = self else {
                    return Single.just([String : PostCounter]())
                }
            
                this.users.merge(newUsers, uniquingKeysWith: { u0, u1 in return u0 })
                return CountersDAO.loadCounters(postKeys: newPostKeys)
            }
            .flatMap { [weak self] (newCounters : [String : PostCounter]) -> Single<Bool> in
                print2("[loadDataObservable] step 4")
                
                guard let this = self else {
                    return Single.just(false)
                }
                
                print2("Loaded \(newCounters.count) post counters")
                
                this.counters.merge(newCounters, uniquingKeysWith: { p0, p1 in return p0 })
                return Single.just(true)
            }
            .do(onSuccess: { [weak self] (result: Bool) in
                // TODO KINE: see postIsSocialAndFromDeletedUser (Android)
                print2("[loadDataObservable] step 5")
                
                guard let this = self else {
                    return
                }

                if this.firstChunk {
                    this.onFirstChunkLoaded()
                }
                
                // Concurrent load of same posts can happend (e.g: on first check in)
                newPosts = newPosts
                    .filter { post in
                        return !this.posts.contains(where: { otherPost in otherPost == post })
                    }
                
                this.originalPosts += newPosts
                this.originalPosts.sort(by: this.sortFunction)
                this.posts = this.reorderPostsByEvenGroup()
                this.tableOperationSubject.onNext(TableOperation.ReloadOperation())
            })
    }
    
    func reorderPostsByEvenGroup() -> [OrbisPost] {
        var newPosts: [OrbisPost] = []
        var newEvents: [OrbisPost] = []
        self.originalPosts.forEach({ (post) in
            if let type = post.typeEnum() {
                switch type {
                case .checkIn, .conqueredPlace, .lostPlace, .wonPlace:
                    newEvents.append(post)
                    return
                default:
                    break
                }
            }
            
            newPosts.append(post)
        })
        
        var firstIsActivity = false
        if let first = self.posts.first {
            if let type = first.typeEnum() {
                switch type {
                case .checkIn, .conqueredPlace, .lostPlace, .wonPlace:
                    firstIsActivity = true
                default:
                    break
                }
            }
        }
        
        
        var arr: [OrbisPost] = []
        
        let step1 = 15
        let step2 = 10
        
        while newPosts.count > 0 {
            if firstIsActivity {
                var count2 = 0
                if newEvents.count > step2 {
                    count2 = step2
                } else {
                    count2 = newEvents.count
                }
                
                if count2 > 1 {
                    let newGroup = OrbisPost(type: "EVENT_GROUP")
                    newGroup.eventGroup = []
                    for _ in 0..<count2 {
                        newGroup.eventGroup?.append(newEvents.first!)
                        newEvents.removeFirst()
                    }
                    arr.append(newGroup)
                } else if count2 == 1 {
                    arr.append(newEvents.first!)
                    newEvents.removeFirst()
                }
                
                var count1 = 0
                if newPosts.count > step1 {
                    count1 = step1
                } else {
                    count1 = newPosts.count
                }
                for _ in 0..<count1 {
                    arr.append(newPosts.first!)
                    newPosts.removeFirst()
                }
            } else {
                var count1 = 0
                if newPosts.count > step1 {
                    count1 = step1
                } else {
                    count1 = newPosts.count
                }
                for _ in 0..<count1 {
                    arr.append(newPosts.first!)
                    newPosts.removeFirst()
                }
                
                var count2 = 0
                if newEvents.count > step2 {
                    count2 = step2
                } else {
                    count2 = newEvents.count
                }
                
                if count2 > 1 {
                    let newGroup = OrbisPost(type: "EVENT_GROUP")
                    newGroup.eventGroup = []
                    for _ in 0..<count2 {
                        newGroup.eventGroup?.append(newEvents.first!)
                        newEvents.removeFirst()
                    }
                    arr.append(newGroup)
                } else if count2 == 1 {
                    arr.append(newEvents.first!)
                    newEvents.removeFirst()
                }
            }
        }
        
        while newEvents.count > 0 {
            var count2 = 0
            if newEvents.count > step2 {
                count2 = step2
            } else {
                count2 = newEvents.count
            }
            
            if count2 > 1 {
                let newGroup = OrbisPost(type: "EVENT_GROUP")
                newGroup.eventGroup = []
                for _ in 0..<count2 {
                    newGroup.eventGroup?.append(newEvents.first!)
                    newEvents.removeFirst()
                }
                arr.append(newGroup)
            } else {
                arr.append(newEvents.first!)
                newEvents.removeFirst()
            }
        }
        
        return arr
    }

    func onFirstChunkLoaded() {
        firstChunk = false
        observePostsChildValues()
        observePostCounterChanges()
    }
    
    func observePostsChildValues() {
        PostDAO.postsChildValuesObservers(includeAdditions: shouldObservePostChildAdditions()).forEach { observer in
            observer.subscribe(onNext: { [weak self] data in
                let (event, post) = data
                self?.processChildEvent(event: event, post: post)
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
        }
    }
    
    func processChildEvent(event: DataEventType, post: OrbisPost?) {
        print2("[PostViewModel] processChildEvent \(event.description()) \(post?.postKey ?? "") hashCode: \(hashValue)")
        
        switch event {
        case .childAdded:
            guard
                let post = post,
                !postsBeingLoaded.contains(post.postKey),
                originalPosts.first(where: { $0.postKey == post.postKey}) == nil,
                postShouldBeDisplayed(post: post)
            else {
                return
            }
            
            postsBeingLoaded.insert(post.postKey)
            
            loadDataObservable(postsLoaded: [post])
                .subscribe(onSuccess: { [weak self] _ in
                    self?.postsBeingLoaded.remove(post.postKey)
                }, onError: { error in
                    print2(error)
                })
                .disposed(by: bag)
        
        case .childRemoved:
            if let post = post {
                delete(post: post)
            }
            
        default:
            break
        }
    }
    
    private func observePostCounterChanges() {
        var serverTimestamp: Int64 = 0
        
        if !counters.isEmpty {
            let value = counters.max(by: { p0, p1 in
                let d0 = p0.value.serverDate
                let d1 = p1.value.serverDate
                
                if d0 == nil {
                    return false
                }
                
                if d1 == nil {
                    return true
                }
                
                return d0!.compare(d1!).rawValue == -1
                
            })?.value.serverDate?.timeIntervalSince1970
            
            serverTimestamp = Int64(value ?? 0)
        }

        print2("BasePostsViewModel: observePostCounterChanges timestamp -> \(serverTimestamp)")
        
        CountersDAO.observePostCounterChanges(serverTimestamp: serverTimestamp)
            .forEach { observer in
                observer
                    .subscribe(onNext: { [weak self] result in
                        let (postKey, counter) = result
                        
                        print2("BasePostsViewModel: observePostCounterChanges [1]")
                        
                        guard
                            let this = self,
                            let index = this.tableIndexOf(postKey: postKey),
                            let c = counter
                            //c.notEqual(other: this.counters[postKey])
                        else {
                            return
                        }
                        
                        print2("BasePostsViewModel: observePostCounterChanges [2] index: \(index) likesCount: \(String(describing: c.likesCount)) commentsCount: \(String(describing: c.commentsCount))")
                        
                        this.counters[postKey] = c
                        this.tableOperationSubject.onNext(TableOperation.UpdateOperation(index: index))

                    }, onError: { error in
                        print2(error)
                    })
                    .disposed(by: bag)
            }
    }
    
    func removePosts(groupKey: String) {
        let rolesViewModel = RolesViewModel.instance()
        let groupsBeingFollowed = rolesViewModel.groupsBeingFollowed()
        let placesBeingFollowed = rolesViewModel.placesBeingFollowed()
        
        originalPosts.removeAll { (post: OrbisPost) -> Bool in
            if post.sponsored == true {
                return false
            }

            if let placeKey = post.placeKey, placesBeingFollowed.contains(placeKey) {
                return false
            }

            if post.winnerGroupKey == groupKey {
                let loserGroupKey = post.loserGroupKey ?? ""
                return !groupsBeingFollowed.contains(loserGroupKey)
            }
            
            if post.loserGroupKey == groupKey {
                let winnerGroupKey = post.winnerGroupKey ?? ""
                return !groupsBeingFollowed.contains(winnerGroupKey)
            }
            
            return false
        }
        posts = reorderPostsByEvenGroup()
        
        tableOperationSubject.onNext(TableOperation.ReloadOperation())
    }
    
    func removePosts(placeKey: String) {
        let rolesViewModel = RolesViewModel.instance()
        let groupsBeingFollowed = rolesViewModel.groupsBeingFollowed()
        
        originalPosts.removeAll { (post: OrbisPost) -> Bool in
            if post.sponsored == true {
                return false
            }

            if post.placeKey != placeKey {
                return false
            }
            
            if let k = post.winnerGroupKey, groupsBeingFollowed.contains(k) {
                return false
            }
            
            if let k = post.loserGroupKey, groupsBeingFollowed.contains(k) {
                return false
            }
            
            return true
        }
        posts = reorderPostsByEvenGroup()
        
        tableOperationSubject.onNext(TableOperation.ReloadOperation())
    }
    
    func removePost(postKey: String?) {
        print2("BasePostsViewModel removePost \(postKey ?? "")")
        
        guard
            let indexOnPostsList = indexOf(postKey: postKey),
            let indexOnTable = tableIndexOf(postKey: postKey)
        else {
            return
        }
        
        print2("BasePostsViewModel removePost indexes: \(indexOnPostsList) \(indexOnTable)")
        if let index = originalPosts.firstIndex(where: { $0.postKey == postKey }) {
            originalPosts.remove(at: index)
        }
        
        let post = posts[indexOnPostsList]
        if let type = post.typeEnum(), type == .eventGroup {
            if let index = post.eventGroup?.firstIndex(where: { $0.postKey == postKey }) {
                post.eventGroup?.remove(at: index)
            }
            if post.eventGroup!.count < 1 {
                posts.remove(at: indexOnPostsList)
                tableOperationSubject.onNext(TableOperation.DeleteOperation(index: indexOnTable))
            } else {
                tableOperationSubject.onNext(TableOperation.UpdateOperation(index: indexOnTable))
            }
        } else {
            posts.remove(at: indexOnPostsList)
            tableOperationSubject.onNext(TableOperation.DeleteOperation(index: indexOnTable))
        }
    }
    
    private func delete(post: OrbisPost) {
        PostDAO.delete(post: post)
            .subscribe(onSuccess: { [weak self] _ in
                guard
                    let this = self
                else {
                    return
                }
                
                this.removePost(postKey: post.postKey)

            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    private func observeLogout() {
        HelperRepository.instance()
            .logoutObservable
            .subscribe(onNext: { [weak self] _ in
                self?.onLogout()
            })
            .disposed(by: bag)
    }
    
    func observeHomeViewModel(radarTab: RadarTab?) {
        let hvm = HomeViewModel.instance()
        
        if !adMobsEnabled() {
            return
        }
        
        /*
        hvm.adMobLoadedSubject
            .subscribe(onNext: { [weak self] data in
                let (radarTab2, adMob) = data
                
                guard
                    let this = self,
                    radarTab == radarTab2
                else {
                    return
                }

                this.onAdMobLoaded(adMob: adMob)
            })
            .disposed(by: bag)
        */
    }

    func resetFirstChunk() {
        firstChunk = true
    }
    
    func checkForDuplicatedPosts() {
        posts.forEach { post in
            let duplicatedPosts = posts.filter { otherPost in otherPost.postKey == post.postKey }
            if duplicatedPosts.count > 1 {
                print2("Panic!!! Duplicated posts \(post.postKey ?? "") \(post.type ?? "")")
            }
        }
    }
    
    func onScrolled(position: Int) {
        print2("[AdMob] onScrolled position: \(position) maxScrollPosition: \(maxScrollPosition)")
        
        if maxScrollPosition >= position {
            return
        }
        
        maxScrollPosition = position
        
        // Plus x ==> load in advance
        let requiredAdsCount = requiredAdsCountUntilPosition(position: position + 5)
        
        print2("[AdMob] onScrolled adsCount: \(getAdsCount()) requiredAdsCount: \(requiredAdsCount)")
        
        if getAdsCount() < requiredAdsCount {
            HomeViewModel.instance().moreAdMobsRequiredSubject.onNext(true)
        }
    }
    
    func getAdsCount() -> Int {
        return adMobs.count
    }
    
    private func adsCountBeforePosition(position: Int) -> Int {
        return min((position.double / adsFrequency.double).rounded(FloatingPointRoundingRule.down).int, getAdsCount())
    }
    
    private func requiredAdsCountUntilPosition(position: Int) -> Int {
        return (position.double / adsFrequency.double).rounded(FloatingPointRoundingRule.down).int
    }

    private func onAdMobLoaded(adMob: GADUnifiedNativeAd) {
        print2("[AdMob] [BasePostsViewModel] onAdMobLoaded")
        
        let adsCount = adsCountBeforePosition(position: maxScrollPosition)
        let requiredAdsCount = requiredAdsCountUntilPosition(position: maxScrollPosition)
        let needsAdMob = adsCount < requiredAdsCount
        
        if needsAdMob {
            adMobs.append(adMob)
            var position = getAdsCount() * adsFrequency
            print2("[AdMob] [BasePostsViewModel] onAdMobLoaded insertAtPosition: \(position) numberOfItems: \(numberOfItems()) requiredAdsCountUntilPosition: \(requiredAdsCount) maxScrollPosition: \(maxScrollPosition)")
            let _ = numberOfItems(debug: true)
            tableOperationSubject.onNext(TableOperation.InsertOperation(start: position, end: position))
        }
    }

    func getCellType(indexPath: IndexPath) -> Cells {
        if (adMobsEnabled()
            && (indexPath.row % adsFrequency == 0)
            && indexPath.row > 0
            && getAdsCount() >= indexPath.row / adsFrequency) {
            return Cells.adMobCell
        }
        else {
            let post = getPost(indexPath: indexPath, searchInEventGroup: false)
            return post.typeEnum()?.getCellType() ?? Cells.textPostCell
        }
    }
    
    func handle(option: PostMenuOptions, post: OrbisPost) {
        switch option {
        case .deletePost:
            delete(post: post)
        
        case .hidePost:
            hide(post: post)
        
        case .reportPost:
            break
        }
    }
    
    private func hide(post: OrbisPost) {
        guard let user = UserDefaultsRepository.instance().getMyUser() else {
            baseSubject.onNext(Words.errorNoUserHidePost)
            return
        }
        HiddenPostViewModel.instance().hide(userId: user.uid, postKey: post.postKey)
    }
    
    func postShouldBeDisplayed(post: OrbisPost) -> Bool {
        return true
    }
}
