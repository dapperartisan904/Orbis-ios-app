//
//  UserDefaultsRepository.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import DefaultsKit

extension DefaultsKey {
    static let activeGroup = Key<Group>("activeGroup")
    static let myUser = Key<OrbisUser>("myUser")
    static let location = Key<Coordinates>("location")
    static let language = Key<String>("language")
    static let debug = Key<String>("debug")
    
    // [OrbisPost.post.imageUrl : PHAsset.localIdentifier]
    static let localPostAssets = Key<[String : String]>("localPostAssets")
}

class UserDefaultsRepository {

    var language: OrbisLanguage?
    var languageBundle: Bundle?
    var defaultLanguageBundle: Bundle?
    
    private static var shared: UserDefaultsRepository = {
        let udr = UserDefaultsRepository()
        udr.language = udr.getLanguage()
        print2("Udr language at init: \(udr.language?.rawValue ?? "")")
        
        if  let l = udr.language,
            let path = Bundle.main.path(forResource: l.rawValue, ofType: "lproj") {
            udr.languageBundle = Bundle(path: path)
        }
        
        if let path = Bundle.main.path(forResource: OrbisLanguage.english.rawValue, ofType: "lproj") {
            udr.defaultLanguageBundle = Bundle(path: path)
        }
        
        return udr
    }()
    
    static func instance() -> UserDefaultsRepository {
        return UserDefaultsRepository.shared
    }
    
    private init() { }
    
    func getActiveGroup() -> Group? {
        return Defaults.shared.get(for: .activeGroup)
    }
    
    func getMyUser() -> OrbisUser? {
        return Defaults.shared.get(for: .myUser)
    }
    
    func getLocation() -> Coordinates? {
        return Defaults.shared.get(for: .location)
    }
    
    func getLanguage() -> OrbisLanguage? {
        let rawValue = Defaults.shared.get(for: .language)
        return OrbisLanguage.from(value: rawValue)
    }
    
    func getPHAssetId(postImageId: String) -> String? {
        return Defaults.shared.get(for: .localPostAssets)?[postImageId]
    }
    
    func getPHAssetIds() -> [String : String]? {
        return Defaults.shared.get(for: .localPostAssets)
    }
    
    func getDebug() -> String? {
        return Defaults.shared.get(for: .debug)
    }
    
    func hasMyUser() -> Bool {
        return getMyUser() != nil
    }
    
    func setActiveGroup(group: Group?) {
        guard let group = group else {
            Defaults.shared.clear(.activeGroup)
            return
        }
        Defaults.shared.set(group, for: .activeGroup)
    }
    
    func setMyUser(user: OrbisUser?) {
        guard let user = user else {
            Defaults.shared.clear(.myUser)
            return
        }
        Defaults.shared.set(user, for: .myUser)
    }
    
    func setLocation(location: Coordinates?) {
        guard let location = location else {
            Defaults.shared.clear(.location)
            return
        }
        Defaults.shared.set(location, for: .location)
    }
    
    func setLanguage(language: OrbisLanguage?) {
        self.language = language
        
        guard let l = language else {
            languageBundle = nil
            Defaults.shared.clear(.language)
            return
        }
        
        if let path = Bundle.main.path(forResource: l.rawValue, ofType: "lproj") {
            languageBundle = Bundle(path: path)
        }
        
        Defaults.shared.set(l.rawValue, for: .language)
    }
    
    func setPHAssetId(postImageId: String, phAssetId: String) {
        print2("[UDR] setPHAssetId postImageId: \(postImageId) phAssetId: \(phAssetId)")
        var dict = Defaults.shared.get(for: .localPostAssets) ?? [String : String]()
        dict[postImageId] = phAssetId
        Defaults.shared.set(dict, for: .localPostAssets)
    }
    
    func setDebug(debug: String?) {
        guard let debug = debug else {
            Defaults.shared.clear(.debug)
            return
        }
        Defaults.shared.set(debug, for: .debug)
    }
}

