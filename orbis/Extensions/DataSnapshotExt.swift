//
//  DataSnapshotExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import CodableFirebase
import FirebaseDatabase
import FirebaseFirestore

extension DataSnapshot {
    
    func firstChild<T : Decodable>(type: T.Type) -> T? {
        guard let child = children.nextObject() as? DataSnapshot,
             let value = child.value
        else {
            return nil
        }
        
        return try? FirebaseDecoder().decode(type, from: value)
    }
    
    func valueToType<T : Decodable>(type: T.Type) -> T? {
        guard let val = value else {
            return nil
        }
        return try? FirebaseDecoder().decode(type, from: val)
    }
}

extension Timestamp: TimestampType { }

enum FirebaseDate: Encodable {
    case date(Date)
    case serverTimestamp
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .date(date):
            try container.encode(date)
        case .serverTimestamp:
            let dict = ServerValue.timestamp().reduce(into: [:], { $0[$1.key.base as! String] = $1.value as? String })
            try container.encode(dict)
        }
    }
}

extension Optional where Wrapped == Date {
    var firebaseDate: FirebaseDate {
        switch self {
        case let .some(date): return .date(date)
        case .none: return .serverTimestamp
        }
    }
}

extension DataEventType {
    
    func description() -> String {
        switch self {
        case .childAdded:
            return "childAdded"
        case .childChanged:
            return "childChanged"
        case .childMoved:
            return "childMoved"
        case .childRemoved:
            return "childRemoved"
        case .value:
            return "value"
        }
    }
    
}
