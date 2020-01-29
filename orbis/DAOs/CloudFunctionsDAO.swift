//
//  CloudFunctionsDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 21/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebaseDatabase
import RxFirebaseFunctions
import FirebaseFunctions

class CloudFunctionsDAO {
    
    static func handlePresenceEvent(
        placeKey: String,
        groupKey: String?,
        userKey: String,
        eventType: PresenceEventType) -> Single<HandlePresenceEventResponse?> {
        
        let params: [String : Any?] = [
            "flavor" : orbisFlavor(),
            "content-type" : "application/json",
            "placeKey" : placeKey,
            "groupKey" : groupKey,
            "userKey" : userKey,
            "eventType" : eventType.rawValue,
            "windowTime" : checkInLifeTime
        ]

        return Functions.functions()
            .httpsCallable("handlePresenceEventMobile3").rx
            .call(params)
            .asSingle()
            .map { (result: HTTPSCallableResult) -> HandlePresenceEventResponse? in
                //print2("handlePresenceEventMobile2 result \(result.data)")
                
                guard let str = result.data as? String else {
                    return nil
                }

                //print2("handlePresenceEventMobile2 [1]")
                print2("handlePresenceEventMobile3 \(str)")
                
                for error in CloudFunctionsErrors.allCases {
                    if str.contains(error.rawValue, caseSensitive: false) {
                        print2("handlePresenceEventMobile3 [2]")
                        return HandlePresenceEventResponse(error: error.rawValue)
                    }
                }

                print2("handlePresenceEventMobile3 [2]")
                
                guard let data = str.data(using: String.Encoding.utf8) else {
                    return nil
                }
                
                print2("handlePresenceEventMobile3 [3]")
                
                do {
                    let response = try JSONDecoder().decode(HandlePresenceEventResponse.self, from: data)
                    return response
                } catch {
                    print2("handlePresenceEventMobile3 [4] \(error)")
                    return nil
                }
            }
    }
    
    static func pointsData(placeKey: String) -> Single<[PointsData]?> {
        let params: [String : Any?] = [
            "flavor" : orbisFlavor(),
            "placeKey" : placeKey
        ]
        
        return Functions.functions()
            .httpsCallable("getPointsDataMobile").rx
            .call(params)
            .asSingle()
            .map { (result: HTTPSCallableResult) -> [PointsData]? in
                print2("pointsData result \(result.data)")
                
                guard
                    let dict = result.data as? [String : Any],
                    let res = dict["result"] as? [[String : Any]]
                else {
                    print2("decode pointsData early return [1]")
                    return nil
                }
                
                var array = [PointsData]()
                
                res.forEach { item in
                    guard
                        let groupKey = item["groupKey"] as? String,
                        let placeKey = item["placeKey"] as? String,
                        let percentage = item["percentage"] as? Double
                    else {
                        print2("decode pointsData early return [2]")
                        return
                    }
                    
                    array.append(PointsData(groupKey: groupKey, placeKey: placeKey, percentage: percentage))
                }
                
                return array
        }
    }
    
    static func sendReportEmail(report: OrbisReport) -> Single<Bool> {
        let myUser = UserDefaultsRepository.instance().getMyUser()
        
        var html = "<p>Reported by: \(myUser?.username ?? "") - \(myUser?.email ?? "")</p>"
        html += "<p>Message: \(report.message ?? "")</p>"
        
        var dynamicLinkParams = ""
        
        if let k = report.placeKey {
            dynamicLinkParams += "&placeKey=\(k)"
        }
        
        if let k = report.postKey {
            dynamicLinkParams += "&postKey=\(k)"
        }
        
        if let k = report.commentKey {
            dynamicLinkParams += "&commentKey=\(k)"
        }

        let type = report.typeEnum()
        let subject = type == ReportType.feedback ? "Orbis Feedback" : "Orbis Report"
    
        var receiver = "info@orbis.to,rbrauwers@gmail.com"
        report.recipients?.forEach { receiver += ",\($0)"}
        
        print2("Report recipients: \(receiver)")
        
        if type == ReportType.report {
            // TODO KINE: report dynamic links not implemented
        }
        
         let params: [String : Any?] = [
            "flavor" : orbisFlavor(),
            "sender" : "",
            "receiver" : receiver,
            "subject" : subject,
            "body" : "",
            "bodyHtml" : html
         ]

        return Functions.functions()
            .httpsCallable("sendEmailMobile").rx
            .call(params)
            .map { _ in return true }
            .asSingle()
    }
    
    static func sendNotificationToUser(userId: String, data: [String : Any?]) -> Single<Bool> {
        let params: [String : Any?] = [
            "flavor" : orbisFlavor(),
            "userId" : userId,
            "data" : data]
        
        return Functions.functions()
            .httpsCallable("sendNotificationMobile").rx
            .call(params)
            .asSingle()
            .map { _ in return true }
    }
    
    static func sendNotificationToTopic(topic: String, data: [String : Any?]) -> Single<Bool> {
        var finalData = data
        finalData["topic"] = topic
        
        let params: [String : Any?] = [
            "flavor" : orbisFlavor(),
            "topic" : topic,
            "data" : finalData]
        
        print2("sendNotificationToTopic \(params)")
        
        return Functions.functions()
            .httpsCallable("sendNotificationToTopicMobile").rx
            .call(params)
            .asSingle()
            .map { _ in return true }
    }
    
    static func checkInAtTemporaryPlaceIsAllowed(userKey: String, coordinates: Coordinates) -> Single<Bool> {
        let params: [String : Any?] = [
            "flavor" : orbisFlavor(),
            "userKey" : userKey,
            "latitude" : coordinates.latitude,
            "longitude" : coordinates.longitude
        ]
        
        return Functions.functions()
            .httpsCallable("checkInAtTemporaryPlaceIsAllowedMobile").rx
            .call(params)
            .asSingle()
            .flatMap { (result: HTTPSCallableResult) -> Single<Bool> in
                guard
                    let str = result.data as? String,
                    let data = str.data(using: String.Encoding.utf8)
                else {
                    return Single.error(OrbisErrors.generic)
                }
                
                print2("checkInAtTemporaryPlaceIsAllowedMobile result[2]: \(String(describing: str))")
                
                do {
                    let response = try JSONDecoder().decode(CheckInIsAllowedResponse.self, from: data)
                    
                    if response.success == true {
                        return Single.just(true)
                    }
                    else if let error = response.error {
                        if let _ = CloudFunctionsErrors(rawValue: error) {
                            return Single.error(OrbisErrors.checkInAtTemporaryPlaceNotAllowed)
                        }
                    }
                    
                    return Single.error(OrbisErrors.generic)
                } catch {
                    print2("checkInAtTemporaryPlaceIsAllowedMobile [4] \(error)")
                    return Single.error(OrbisErrors.generic)
                }
            }
    }
}
