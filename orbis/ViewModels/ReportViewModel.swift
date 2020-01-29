//
//  ReportViewModel.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 05/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import PKHUD

class ReportViewModel : OrbisViewModel {
    
    func saveFeedback(message: String?) {
        guard
            let m = message, !m.isWhitespace,
            let reportKey = ReportDAO.newKey()
        else {
            return
        }
        
        let report = OrbisReport(
            reportKey: reportKey,
            type: ReportType.feedback.rawValue,
            userKey: UserDefaultsRepository.instance().getMyUser()?.uid,
            message: m)
        
        ReportDAO.save(report: report)
            .subscribe(onSuccess: { _ in
                HUD.flash(.label(Words.reportSent.localized), delay: 1.5)
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
    func saveReport(post: OrbisPost, message: String?) {
        let report = OrbisReport(type: ReportType.report.rawValue)
        report.postKey = post.postKey
        report.postType = post.type
        report.groupKey = post.winnerGroupKey
        saveReport(report: report, message: message)
    }
    
    func saveReport(place: Place, message: String?) {
        let report = OrbisReport(type: ReportType.report.rawValue)
        report.placeKey = place.key
        report.groupKey = place.dominantGroupKey
        saveReport(report: report, message: message)
    }
    
    private func saveReport(report: OrbisReport, message: String?) {
        guard
            let m = message, !m.isWhitespace,
            let reportKey = ReportDAO.newKey()
        else {
            return
        }
        
        report.reportKey = reportKey
        report.message = m
        report.userKey = UserDefaultsRepository.instance().getMyUser()?.uid
        
        ReportDAO.save(report: report)
            .subscribe(onSuccess: { _ in
                HUD.flash(.label(Words.reportSent.localized), delay: 1.5)
            }, onError: { error in
                print2(error)
            })
            .disposed(by: bag)
    }
    
}
