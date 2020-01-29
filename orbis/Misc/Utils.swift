//
//  Utils.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Photos
import FirebaseDatabase

func print2(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    var idx = items.startIndex
    let endIdx = items.endIndex
    
    repeat {
        Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
        idx += 1
    }
    while idx < endIdx
    
    #endif

}

func hideKeyboardFromApplication() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
}

func contentType(fileExtension: String) -> String? {
    let types = [
        "flv" : "video/x-flv",
        "mp4" : "video/mp4",
        "m3u8" : "application/x-mpegURL",
        "ts" : "video/MP2T",
        "3gp" : "video/3gpp",
        // TODO KINE: mov extension
        //"mov" : "video/quicktime",
        "mov" : "video/mp4",
        "avi" : "video/x-msvideo",
        "wmv" : "video/x-ms-wmv",
    ]
    return types[fileExtension.lowercased()]
}

func shouldResetHomeTopCardHeight(offset: CGFloat) -> Bool {
    let topCardDefHeight: CGFloat = 200
    return offset < topCardDefHeight
}

func isSandbox() -> Bool {
    return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String == "orbis_sandbox"
}

func isProduction() -> Bool {
    return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String == "Orbis"
}

func orbisFlavor() -> String {
    return isProduction() ? "production" : "sandbox"
}

func database() -> Database {
    if isSandbox() {
        return Database.database()
    }
    else if isProduction() {
        return Database.database(url: "https://orbis-7b9a7-d166e.firebaseio.com")
    }
    else {
        return Database.database(url: "invalid_database")
    }
}

func orbisDefaultImageRequestOptions() -> PHImageRequestOptions {
    let options = PHImageRequestOptions()
    options.isSynchronous = false
    options.resizeMode = .exact
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    return options
}

extension Array where Element == OrbisUser {
    func sort(roles: [String : [Roles]]) -> [OrbisUser] {
        return self.sorted(by: { u0, u1 in
            let r0 = roles[u0.uid] ?? [Roles]()
            let r1 = roles[u1.uid] ?? [Roles]()
            let a0 = r0.contains(Roles.administrator)
            let a1 = r1.contains(Roles.administrator)
            
            if a0 && !a1 {
                return true
            }
            
            if a1 && !a0 {
                return false
            }
            
            return u0.username.caseInsensitiveCompare(u1.username) == ComparisonResult.orderedAscending
        })
    }
}
