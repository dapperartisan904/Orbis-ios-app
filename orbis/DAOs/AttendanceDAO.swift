//
//  AttendanceDAO.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 25/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CodableFirebase
import RxSwift
import RxFirebaseDatabase

class AttendanceDAO {
    
    private static let attendancesByPostReference = database().reference(withPath: "attendancesByPost")
    private static let attendancesByUserReference = database().reference(withPath: "attendancesByUser")
    
    private static func ref(postKey: String) -> DatabaseReference {
        return attendancesByPostReference.child(postKey)
    }
    
    private static func ref(postKey: String, userKey: String) -> DatabaseReference {
        return ref(postKey: postKey).child(userKey)
    }
    
    private static func ref(userKey: String) -> DatabaseReference {
        return attendancesByUserReference.child(userKey)
    }
    
    private static func ref(userKey: String, postKey: String) -> DatabaseReference {
        return ref(userKey: userKey).child(postKey)
    }

    static func loadAttendances(postKey: String, limit: UInt?) -> Single<[Attendance]> {
        var reference: DatabaseQuery = ref(postKey: postKey)
        if let limit = limit {
            reference = reference.queryOrderedByKey().queryLimited(toFirst: limit)
        }

        return reference.rx
            .observeSingleEvent(.value)
            .map { (snapshot : DataSnapshot) -> [Attendance] in
                var attendances = [Attendance]()
                for case let child as DataSnapshot in snapshot.children {
                    if let attendance = child.valueToType(type: Attendance.self), attendance.statusEnum() == .attending {
                        attendances.append(attendance)
                    }
                }
                return attendances
            }
    }
    
    static func loadAttendances(postKeys: [String], limit: UInt?) -> Single<[String : [Attendance]]> {
        return Observable
            .from(postKeys)
            .flatMap { (postKey : String) -> Single<[Attendance]> in
                return loadAttendances(postKey: postKey, limit: limit)
            }
            .toArray()
            .map { (attendances : [[Attendance]]) -> [String : [Attendance]] in
                var map = [String : [Attendance]]()
                attendances.forEach { attendancesByPost in
                    if let attendance = attendancesByPost.first {
                        map[attendance.postKey] = attendancesByPost
                    }
                }
                return map
            }
    }
    
    static func saveAttendance(attendance: Attendance) -> Single<Bool> {
        let data = try! FirebaseEncoder().encode(attendance)
        
        return ref(userKey: attendance.userId, postKey: attendance.postKey).rx
            .setValue(data)
            .flatMap { _ in
                return ref(postKey: attendance.postKey, userKey: attendance.userId).rx
                    .setValue(data)
            }
            .map { _ in return true }
    }

}
