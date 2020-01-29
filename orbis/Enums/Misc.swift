//
//  Misc.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

typealias ActionAndError = (OrbisAction, Words)

public enum Storyboards: String {
    case
        createGroup="CreateGroup",
        groups="Groups",
        home="Home",
        places="Places",
        posts="Posts",
        register="Register",
        settings="Settings",
        users="Users"
}

public class ViewControllerInfo : Equatable {
    public static func == (lhs: ViewControllerInfo, rhs: ViewControllerInfo) -> Bool {
        return lhs.name == rhs.name
    }
    
    public var name: String
    public var storyboard: Storyboards
    
    static let radar = ViewControllerInfo(name: "RadarViewController", storyboard: .home)
    static let map = ViewControllerInfo(name: "MapViewController", storyboard: .home)
    static let groups = ViewControllerInfo(name: "GroupsViewController", storyboard: .home)
    static let myFeed = ViewControllerInfo(name: "MyFeedViewController", storyboard: .home)
    static let distanceFeed = ViewControllerInfo(name: "DistanceFeedViewController", storyboard: .home)
    static let test = ViewControllerInfo(name: "TestViewController", storyboard: .home)
    static let videoPlayer = ViewControllerInfo(name: "VideoPlayerController", storyboard: .home)
    static let postGallery = ViewControllerInfo(name: "PostGalleryViewController", storyboard: .home)
    static let comments = ViewControllerInfo(name: "CommentsViewController", storyboard: .home)
    static let commentImageSelector = ViewControllerInfo(name: "CommentImageSelectorViewController", storyboard: .home)
    
    static let colors = ViewControllerInfo(name: "ColorsViewController", storyboard: .createGroup)
    static let createGroup = ViewControllerInfo(name: "CreateGroupViewController", storyboard: .createGroup)

    static let login = ViewControllerInfo(name: "LoginViewController", storyboard: .register)
    static let register = ViewControllerInfo(name: "RegisterViewController", storyboard: .register)
    static let forgotPassword = ViewControllerInfo(name: "ForgotPasswordViewController", storyboard: .register)
    
    static let settings = ViewControllerInfo(name: "SettingsViewController", storyboard: .settings)
    static let settingsPostMenu = ViewControllerInfo(name: "SettingsPostMenuViewController", storyboard: .settings)

    static let checkIn = ViewControllerInfo(name: "CheckInViewController", storyboard: .places)
    static let createPlaceStepOne = ViewControllerInfo(name: "CreatePlaceStepOneViewController", storyboard: .places)
    static let createPlaceStepTwo = ViewControllerInfo(name: "CreatePlaceStepTwoViewController", storyboard: .places)
    static let place = ViewControllerInfo(name: "PlaceViewController", storyboard: .places)
    static let placeDescription = ViewControllerInfo(name: "PlaceDescriptionViewController", storyboard: .places)
    static let placeFeed = ViewControllerInfo(name: "PlaceFeedViewController", storyboard: .places)
    static let placeCheckIn = ViewControllerInfo(name: "PlaceCheckInViewController", storyboard: .places)
    static let events = ViewControllerInfo(name: "EventsViewController", storyboard: .places)
    static let createEvent = ViewControllerInfo(name: "CreateEventViewController", storyboard: .places)
    static let attendances = ViewControllerInfo(name: "AttendancesViewController", storyboard: .places)
    
    static let group = ViewControllerInfo(name: "GroupViewController", storyboard: .groups)
    static let dominatedPlaces = ViewControllerInfo(name: "DominatedPlacesViewController", storyboard: .groups)
    static let groupFeed = ViewControllerInfo(name: "GroupFeedViewController", storyboard: .groups)
    static let groupMembers = ViewControllerInfo(name: "GroupMembersViewController", storyboard: .groups)
    static let memberMenu = ViewControllerInfo(name: "MemberMenuViewController", storyboard: .groups)
    
    static let user = ViewControllerInfo(name: "UserViewController", storyboard: .users)
    static let userGroups = ViewControllerInfo(name: "UserGroupsViewController", storyboard: .users)
    static let userPlaces = ViewControllerInfo(name: "UserPlacesViewController", storyboard: .users)
    static let lastMessages = ViewControllerInfo(name: "LastMessagesViewController", storyboard: .users)
    static let chat = ViewControllerInfo(name: "ChatViewController", storyboard: .users)
    static let chatGallery = ViewControllerInfo(name: "ChatGalleryViewController", storyboard: .users)
    static let chatImageSelector = ViewControllerInfo(name: "ChatImageSelectorViewController", storyboard: .users)
    
    static let createPostStepOne = ViewControllerInfo(name: "CreatePostStepOneViewController", storyboard: .posts)
    static let createPostStepTwo = ViewControllerInfo(name: "CreatePostStepTwoViewController", storyboard: .posts)
    static let postMenu = ViewControllerInfo(name: "PostMenuViewController", storyboard: .posts)
    
    init(name: String, storyboard: Storyboards) {
        self.name = name
        self.storyboard = storyboard
    }
}

enum Segue : String {
    case place="place"
}

enum Navigation {
    case chat(viewModel: ChatViewModel)
    case chatGallery(msg: ChatMessage)
    case chatImageSelector(chatViewModel: ChatViewModel)
    case commentImageSelector(commentsViewModel: CommentsViewModel)
    case createEvent(viewModel: CreateEventViewModel)
    case createPlaceStepTwo(viewModel: CreatePlaceViewModel)
    case createPostStepOne(viewModel: CreatePostViewModel)
    case createPostStepTwo(viewModel: CreatePostViewModel)
    case group(group: Group)
    case createGroup()
    case editGroup(group: Group)
    case home()
    case map()
    case place(placeWrapper: PlaceWrapper)
    case register()
    case user(user: OrbisUser)
    case video(post: OrbisPost)
    case gallery(post: OrbisPost, imageIndex: Int?)
    case comments(postWrapper: PostWrapper)
    case attendances(viewModel: AttendancesViewModel)
}

protocol PopNavigation {
    func match(vc: UIViewController) -> Bool
}

class PopToViewController<VC : OrbisViewController> : PopNavigation {
    let type: VC.Type
    
    init(type: VC.Type) {
        self.type = type
    }
    
    func match(vc: UIViewController) -> Bool {
        return vc is VC
    }
    
    // class BasePostsViewController<VM : BasePostsViewModel & PostsViewModelContract> : OrbisViewController, PostCellDelegate {
    // func valueToType<T : Decodable>(type: T.Type) -> T? {
}

public enum Cells: String {
    case
        adMobCell = "AdMobCell",
        checkInPostCell="CheckInPostCell",
        color="ColorCell",
        comment="CommentCell",
        dominatedPlace="DominatedPlaceCell",
        event="EventCell",
        group="GroupCell",
        place="PlaceCell",
        placeIcon="PlaceIconCell",
        points="PointsCell",
        imagePostCell="ImagePostCell",
        lastMessage="LastMessageCell",
        leftChatText="LeftChatTextCell",
        leftChatImage="LeftChatImageCell",
        lostPlacePostCell="LostPlacePostCell",
        postGallery="PostGalleryCell",
        rightChatText="RightChatTextCell",
        rightChatImage="RightChatImageCell",
        settingsAdminCell="SettingsAdminCell",
        settingsGroupCell="SettingsGroupCell",
        settingsPlaceCell="SettingsPlaceCell",
        settingsPostCell="SettingsPostCell",
        testCell="TestCell",
        textPostCell="TextPostCell",
        thumbnailCell="ThumbnailCell",
        userCell="UserCell",
        userPlace="UserPlaceCell",
        videoPostCell="VideoPostCell",
        videoPostCell2="VideoPostCell2",
        videoPostCell3="VideoPostCell3",
        wonPlacePostCell="WonPlacePostCell",
        evenGroupCell="EventGroupCell"
}

public enum CloudFunctionsErrors : String, CaseIterable {
    case
        checkInNotAllowed = "CHECKIN_NOT_ALLOWED",
        checkInAtTemporaryPlaceNotAllowed = "CHECKIN_AT_TEMPORARY_PLACE_NOT_ALLOWED",
        checkInWithGroupNotAllowed = "CHECKIN_WITH_GROUP_NOT_ALLOWED"
}

public enum OrbisErrors: Error {
    case
        applicationNotReady,
        checkInAtTemporaryPlaceNotAllowed,
        emptyResult,
        generic,
        groupNotExist,
        incorrectPwd,
        placeChangeNotExist,
        placeDontHaveDominantGroup,
        placeNotExist,
        noLoggedUser,
        undefinedBundle,
        userNotExist
    
    func word() -> Words? {
        switch self {
        case .checkInAtTemporaryPlaceNotAllowed:
            return Words.errorCheckInTemporaryPlace
        case .generic:
            return Words.errorGeneric
        case .userNotExist:
            return Words.errorUserNotExists
        default:
            return nil
        }
    }
}

public enum OrbisAction {
    case
        emptyContent,
        signIn,
        signOut,
        taskStarted,
        taskFinished,
        taskFailed
}

public enum OrbisUnit : String {
    case miles="MILES", km="KM"
}

public enum TaskStatus {
    case loading, finished
}

public enum Roles: Int {
    case
        administrator=0,
        member=1,
        follower=2
}

public enum RoleStatus {
    case
        active,
        inactive,
        undetermined
    
    func dual() -> RoleStatus {
        switch self {
        case .active:
            return .inactive
        case .inactive:
            return .active
        case .undetermined:
            return .undetermined
        }
    }
}

public enum PresenceEventType: String {
    case
        checkIn="CHECK_IN",
        checkOut="CHECK_OUT",
        undetermined="UNDETERMINED"
}

public class TableOperation {
    
    public class ReloadOperation : TableOperation { }
    
    public class InsertOperation : TableOperation {
        var start: Int
        var end: Int
        var scroll: Bool
        
        init(start: Int, end: Int, scroll: Bool = false) {
            self.start = start
            self.end = end
            self.scroll = scroll
        }
        
        func indexes() -> [IndexPath] {
            var i = [IndexPath]()
            
            for j in start...end {
                i.append(IndexPath(row: j, section: 0))
            }
            
            return i
        }
    }
    
    public class DeleteOperation : TableOperation {
        let index: Int
        let section: Int
        
        init(index: Int) {
            self.index = index
            self.section = 0
        }
        
        init(index: Int, section: Int) {
            self.index = index
            self.section = section
        }
    }
    
    public class UpdateOperation : TableOperation {
        var index: Int?
        var itemKey: String?
        var itemKeys: [String]?
        var indexPaths: [IndexPath]?
        
        init(index: Int) {
            self.index = index
        }
        
        init(indexPaths: [IndexPath]) {
            self.indexPaths = indexPaths
        }
        
        init(itemKey: String) {
            self.itemKey = itemKey
        }
        
        init(itemKeys: [String]) {
            self.itemKeys = itemKeys
        }
        
        func allKeys() -> [String] {
            var keys = [String]()
            
            if let k = itemKey {
                keys.append(k)
            }
            
            itemKeys?.forEach {
                keys.append($0)
            }
            
            return keys
        }
    }
}

public enum PlaceSource : String {
    case user="USER", google="GOOGLE", csv="CSV"
}

public enum PlaceType : String, CaseIterable {
    case
        location="place_location",
        house="place_house",
        building="place_building",
        bar="place_bar",
        restaurant="place_restaurant",
        school="place_school",
        twoBuildings="place_two_buildings",
        music="place_music",
        beach="place_beach",
        house2="place_house_2",
        castle="place_castle",
        sportsCenter="place_sports_center",
        shopping="place_shop",
        fastFood="place_fast_food",
        park="place_park",
        temporary="target_grey"

    func valueForDB() -> String {
        switch self {
        case .location:
            return "LOCATION"
        case .house:
            return "HOUSE"
        case .building:
            return "BUILDING"
        case .bar:
            return "BAR"
        case .restaurant:
            return "RESTAURANT"
        case .school:
            return "SCHOOL"
        case .twoBuildings:
            return "TWO_BUILDINGS"
        case .music:
            return "MUSIC"
        case .beach:
            return "BEACH"
        case .house2:
            return "HOUSE_2"
        case .castle:
            return "CASTLE"
        case .sportsCenter:
            return "SPORTS_CENTER"
        case .shopping:
            return "SHOPPING"
        case .fastFood:
            return "FAST_FOOD"
        case .park:
            return "PARK"
        case .temporary:
            return "TEMPORARY"
        }
    }
    
    static func valuesForCreatePlace() -> [PlaceType] {
        return PlaceType.allCases.filter { $0 != PlaceType.temporary }
    }
}

public enum PostType : String {
    case
        conqueredPlace="CONQUERED_PLACE",
        wonPlace="WON_PLACE",
        lostPlace="LOST_PLACE",
        checkIn="CHECK_IN",
        images="SOCIAL",
        video="SOCIAL_VIDEO",
        text="SOCIAL_TEXT",
        event="EVENT",
        eventGroup="EVENT_GROUP"
    
    func isSocial() -> Bool {
        switch self {
        case .images, .video, .text:
            return true
        default:
            return false
        }
    }
    
    func createPostTitle() -> Words? {
        switch self {
        case .images:
            return Words.postImage
        case .text:
            return Words.postText
        case .video:
            return Words.postVideo
        default:
            return nil
        }
    }
    
    func selectButtonTitle() -> Words? {
        switch self {
        case .images:
            return Words.chooseImage
        case .video:
            return Words.chooseVideo
        default:
            return nil
        }
    }
    
    func getCellType() -> Cells {
        switch self {
        case .checkIn, .event:
            return Cells.checkInPostCell
        case .conqueredPlace, .wonPlace:
            return Cells.wonPlacePostCell
        case .lostPlace:
            return Cells.lostPlacePostCell
        case .images:
            return Cells.imagePostCell
        case .text:
            return Cells.textPostCell
        case .video:
            return Cells.videoPostCell3
        case .eventGroup:
            return Cells.evenGroupCell
        }
    }
    
    func isLimitedByDistance() -> Bool {
        switch self {
        case .checkIn, .conqueredPlace, .lostPlace, .wonPlace:
            return true
        default:
            return false
        }
    }
}

public enum LikeType : String, CaseIterable {
    case
        post="posts",
        postImage="postImages",
        comment="comments"
    
    func index() -> Int {
        switch self {
        case .post:
            return 0
        case .postImage:
            return 1
        case .comment:
            return 2
        }
    }
    
    func localizableMsg() -> String {
        switch self {
        case .post:
            return "notification_liked_msg_post"
        case .postImage:
            return "notification_liked_msg_comment"
        case .comment:
            return "notification_liked_msg_image"
        }
    }
}

public enum OrbisLanguage : String, CaseIterable, Codable {
    case english="en",
        portugueseBR="pt-BR",
        russian="ru"
    
    func title() -> String {
        switch self {
        case .english:
            return Words.english.localized
        case .portugueseBR:
            return Words.portuguese.localized
        case .russian:
            return Words.russian.localized
        }
    }
    
    static func from(value: String?) -> OrbisLanguage? {
        return OrbisLanguage.allCases.first(where: { $0.rawValue == value })
    }
}

public enum ReportType : String, CaseIterable {
    case report="REPORT",
        feedback="FEEDBACK"
    
    static func from(value: String?) -> ReportType? {
        return ReportType.allCases.first(where: { $0.rawValue == value })
    }
}

public enum AttendanceStatus : String, CaseIterable {
    case attending="ATTENDING",
        notAttending="NOT_ATTENDING",
        undetermined="UNDETERMINED"
    
    func dual() -> AttendanceStatus {
        switch self {
        case .attending:
            return .notAttending
        case .notAttending:
            return .attending
        case .undetermined:
            return .undetermined
        }
    }
    
    static func from(value: String?) -> AttendanceStatus? {
        return AttendanceStatus.allCases.first(where: { $0.rawValue == value })
    }
}

public enum NotificationKey : String {
    case senderId = "SENDER_ID",
        receiverId = "RECEIVER_ID",
        requestCode = "REQUEST_CODE",
        coordinates = "COORDINATES",
        chatKey = "chatKey",
        commentKey = "commentKey",
        postKey = "postKey",
        postType = "postType",
        title = "title",
        message = "message",
        isLocalizable = "isLocalizable",
        likeType = "likeType",
        groupKey = "groupKey",
        titleLoc = "titleLoc",              // Localizable title
        messageLoc = "messageLoc",          // Localizable msg
        messageArgs = "messageArgs"    // Localizable msg args
}

public enum RequestCode : Int, CaseIterable {
    case openChat = 134,
        openComment = 131,
        openPost = 133,
        liked = 136,
        joined = 137
    
    static func from(value: Int?) -> RequestCode? {
        return RequestCode.allCases.first(where: { $0.rawValue == value })
    }
    
    static func from(value: String?) -> RequestCode? {
        return from(value: Int(value ?? ""))
    }
}

public enum TemporaryPlaceStatus : Int, CaseIterable {
    case created, notCreated, processing, errorGeneric
}

public enum PlaceMenuOptions : CaseIterable {
    case directions, copyAddress, rename, report

    func getWord() -> Words {
        switch self {
        case .directions: return Words.getDirections
        case .copyAddress: return Words.copyAddress
        case .rename: return Words.rename
        case .report: return Words.reportPlace
        }
    }
}

public enum OrbisTutorial : Int {
    
    // Do not change order
    case createGroup,
        createPlace,
        events,
        group,
        homeActiveGroup,
        homeMap,
        homeMap2,
        homeMap3,
        homeGroups,
        homeRadar,
        homeRadarRegistered,
        place,
        place2,
        register
    
    func next() -> OrbisTutorial? {
        switch self {
        case .homeActiveGroup: return .homeMap2
        case .homeMap2: return .homeMap3
        case .homeRadar: return .homeRadarRegistered
        case .place: return .place2
        default: return nil
        }
    }
    
    func userDefaultsKey() -> String {
        return "tutorial_\(rawValue)"
    }
}

func bgScheduler() -> SchedulerType {
    return ConcurrentDispatchQueueScheduler(qos: DispatchQoS.background)
}

func delay(ms: Int, block: @escaping () -> (Void)) {
    let deadlineTime = DispatchTime.now() + .milliseconds(ms)
    DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
        block()
    })
}

func mainAsync(block: @escaping () -> (Void)) {
    DispatchQueue.main.async {
        block()
    }
}

func mainSync(block: @escaping () -> (Void)) {
    DispatchQueue.main.sync {
        block()
    }
}

