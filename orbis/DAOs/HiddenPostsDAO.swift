//
//  HiddenPostsDAO.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 12/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CodableFirebase
import RxSwift

class HiddenPostsDAO {

    private static let reference = database().reference(withPath: "hiddenPostsByUser")

    private static func ref(userId: String) -> DatabaseReference {
        return reference.child(userId)
    }
    
    private static func ref(userId: String, postKey: String) -> DatabaseReference {
        return ref(userId: userId).child(postKey)
    }

    static func hidePost(userId: String, postKey: String) -> Single<Bool> {
        let data = try! FirebaseEncoder().encode(HiddenPost(userId: userId, postKey: postKey, serverDate: nil))
        return HiddenPostsDAO.ref(userId: userId, postKey: postKey).rx
            .setValue(data)
            .map { _ in return true }
    }

    static func loadHiddenPosts(userId: String?) -> Single<[String : HiddenPost]> {
        guard let userId = userId else {
            return Single.just([String : HiddenPost]())
        }
    
        return ref(userId: userId).rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [String : HiddenPost] in
                var dict = [String : HiddenPost]()
                
                for case let snapshot2 as DataSnapshot in snapshot.children {
                    if let obj = snapshot2.valueToType(type: HiddenPost.self) {
                        dict[obj.postKey] = obj
                    }
                }
                
                return dict
            }
    }
    
    static func observeHiddenPostsChildEvents(userId: String, serverTimestamp: Int64) -> Observable<HiddenPost?> {
        return ref(userId: userId)
            .queryOrdered(byChild: "serverTimestamp")
            .queryStarting(atValue: serverTimestamp + 1).rx
            .observeEvent(DataEventType.childAdded)
            .map { (snapshot : DataSnapshot) -> HiddenPost? in
                return snapshot.valueToType(type: HiddenPost.self)
            }
    }
    
}
