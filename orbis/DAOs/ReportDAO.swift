//
//  ReportDAO.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 05/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import Firebase
import RxSwift
import RxFirebaseDatabase
import CodableFirebase

class ReportDAO {
    
    private static let reference = database().reference(withPath: "reports")
    
    static func newKey() -> String? {
        return reference.childByAutoId().key
    }

    static func save(report: OrbisReport) -> Single<Bool> {
        let data = try! FirebaseEncoder().encode(report)
        return reference.child(report.reportKey).rx
            .setValue(data)
            .flatMap { _ in
                return UserDAO.loadAdminsOfGroup(groupKey: report.groupKey)
            }
            .flatMap { (admins : [OrbisUser]) -> Single<Bool> in
                report.recipients = admins.filter { return $0.email != nil }.map { return $0.email! }
                return CloudFunctionsDAO.sendReportEmail(report: report)
            }
    }
}
