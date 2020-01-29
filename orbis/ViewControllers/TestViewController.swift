//
//  TestViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 15/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class TestViewController : OrbisViewController {
    
    private let images = [
        "-LTg3AngTgUpXQQgBitK.jpg",
        "-LTh-weRMXyRA8r4R7tw.jpg",
        "-LTw06Q4AAdKalm_qC2I.jpg",
        "-LUAiTRfSwQnpjwBux02.jpg",
        "-LUBp_8KoFCl5hlKzdqN.png",
        "-LUF1TS6rkeVcxk5QNVX.jpeg",
        "-LUFBTKKfLtAtZGbePHd.jpeg"
    ]
    
    private let rowHeight: CGFloat = 200
    private let imageHeight: CGFloat = 190
    private var didLayoutSubviews = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pieView: OrbisPie!
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    let handlePresenceEventJson = "{\"placeSize\":{\"placeKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"prevPlaceSize\":100,\"actualPlaceSize\":1200},\"dominance\":{\"eventType\":\"DOMINANT_GROUP_NOT_CHANGED\",\"points\":[{\"checkInCount\":1,\"groupKey\":\"-LUom4OAWN6ryBLowu5q\",\"placeKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"lastTimeBecomeDominant\":1549386035814,\"mostRecentCheckinTimestamp\":1549386035110,\"mostRecentCheckinIsExpired\":false,\"percentage\":51},{\"checkInCount\":1,\"groupKey\":\"-LTw06Q4AAdKalm_qC2I\",\"placeKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"lastTimeBecomeDominant\":1547227602284,\"mostRecentCheckinTimestamp\":1549388826077,\"mostRecentCheckinIsExpired\":false,\"percentage\":49}],\"winnerGroup\":{\"colorIndex\":10,\"deleted\":false,\"description\":\"xbdbdbsbssdhdbhs\",\"geohash\":\"6fg0kfdmksjx\",\"imageName\":\"-LUom4OAWN6ryBLowu5q.jpg\",\"key\":\"-LUom4OAWN6ryBLowu5q\",\"location\":{\"latitude\":-29.4726479,\"longitude\":-51.8192191},\"name\":\"Aaaaaaaa\",\"os\":\"ANDROID\",\"solidColorHex\":\"#8BC34A\",\"strokeColorHex\":\"#4A711E\",\"timestamp\":1546000043982},\"loserGroup\":null},\"touchedPlaces\":[{\"key\":\"-LWl3CfYZRcGa266MZw2\",\"size\":30,\"touches\":[{\"count\":1,\"timestamp\":1549353848892,\"touchedPlaceKey\":\"-LWl3CfYZRcGa266MZw2\",\"touchingPlaceKey\":\"-LThVaY1q7mOAg-oe8OD\",\"valid\":true},{\"count\":1,\"timestamp\":1549387113551,\"touchedPlaceKey\":\"-LWl3CfYZRcGa266MZw2\",\"touchingPlaceKey\":\"-LThVbvLwuDFhlW7HtkI\",\"valid\":true},{\"count\":1,\"timestamp\":1549387027846,\"touchedPlaceKey\":\"-LWl3CfYZRcGa266MZw2\",\"touchingPlaceKey\":\"-LThVc9xeVApdcT47TXU\",\"valid\":true},{\"count\":2,\"timestamp\":1549387389341,\"touchedPlaceKey\":\"-LWl3CfYZRcGa266MZw2\",\"touchingPlaceKey\":\"-LThVcKOG1wRlB_Ak9sP\",\"valid\":true},{\"count\":2,\"timestamp\":1549388825449,\"touchedPlaceKey\":\"-LWl3CfYZRcGa266MZw2\",\"touchingPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"valid\":true}]},{\"key\":\"-LThVcKOG1wRlB_Ak9sP\",\"size\":1000,\"touches\":[{\"count\":1,\"timestamp\":1549388825449,\"touchedPlaceKey\":\"-LThVcKOG1wRlB_Ak9sP\",\"touchingPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"valid\":true}]},{\"key\":\"-LThVbvLwuDFhlW7HtkI\",\"size\":200,\"touches\":[{\"count\":2,\"timestamp\":1549387389341,\"touchedPlaceKey\":\"-LThVbvLwuDFhlW7HtkI\",\"touchingPlaceKey\":\"-LThVcKOG1wRlB_Ak9sP\",\"valid\":true},{\"count\":1,\"timestamp\":1549388825449,\"touchedPlaceKey\":\"-LThVbvLwuDFhlW7HtkI\",\"touchingPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"valid\":true}]},{\"key\":\"-LThVc9xeVApdcT47TXU\",\"size\":100,\"touches\":[{\"count\":1,\"timestamp\":1549387113551,\"touchedPlaceKey\":\"-LThVc9xeVApdcT47TXU\",\"touchingPlaceKey\":\"-LThVbvLwuDFhlW7HtkI\",\"valid\":true},{\"count\":2,\"timestamp\":1549387389341,\"touchedPlaceKey\":\"-LThVc9xeVApdcT47TXU\",\"touchingPlaceKey\":\"-LThVcKOG1wRlB_Ak9sP\",\"valid\":true},{\"count\":1,\"timestamp\":1549388825449,\"touchedPlaceKey\":\"-LThVc9xeVApdcT47TXU\",\"touchingPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"valid\":true}]},{\"key\":\"-LThVaY1q7mOAg-oe8OD\",\"size\":32,\"touches\":[{\"count\":1,\"timestamp\":1549387113551,\"touchedPlaceKey\":\"-LThVaY1q7mOAg-oe8OD\",\"touchingPlaceKey\":\"-LThVbvLwuDFhlW7HtkI\",\"valid\":true},{\"count\":1,\"timestamp\":1549387027846,\"touchedPlaceKey\":\"-LThVaY1q7mOAg-oe8OD\",\"touchingPlaceKey\":\"-LThVc9xeVApdcT47TXU\",\"valid\":true},{\"count\":2,\"timestamp\":1549387389341,\"touchedPlaceKey\":\"-LThVaY1q7mOAg-oe8OD\",\"touchingPlaceKey\":\"-LThVcKOG1wRlB_Ak9sP\",\"valid\":true},{\"count\":2,\"timestamp\":1549388825449,\"touchedPlaceKey\":\"-LThVaY1q7mOAg-oe8OD\",\"touchingPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"valid\":true}]}],\"touchedBy\":[{\"count\":1,\"timestamp\":1549353848892,\"touchedPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"touchingPlaceKey\":\"-LThVaY1q7mOAg-oe8OD\",\"valid\":false},{\"count\":1,\"timestamp\":1549387113551,\"touchedPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"touchingPlaceKey\":\"-LThVbvLwuDFhlW7HtkI\",\"valid\":false},{\"count\":1,\"timestamp\":1549387027846,\"touchedPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"touchingPlaceKey\":\"-LThVc9xeVApdcT47TXU\",\"valid\":false},{\"count\":2,\"timestamp\":1549387389341,\"touchedPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"touchingPlaceKey\":\"-LThVcKOG1wRlB_Ak9sP\",\"valid\":false},{\"count\":1,\"timestamp\":1549349692250,\"touchedPlaceKey\":\"-LVxwsk5Gv9Xa7WfpiTG\",\"touchingPlaceKey\":\"-LWl3CfYZRcGa266MZw2\",\"valid\":false}]}"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button.rx.tap
            .bind { _ in
                self.decode()
            }
            .disposed(by: bag)
        
        button2.rx.tap
            .bind { _ in
                //self.nearbySearch()
                //self.findPlace(key: "-LVNvvik-T3u_T-Nspva")
                //self.debugAllPlaces()
                self.debugPlaceLocations()
            }
            .disposed(by: bag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLayoutSubviews {
            didLayoutSubviews = true
            tableView.register(cell: Cells.testCell)
            tableView.rowHeight = rowHeight
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    private func debugAllPlaces() {
        PlaceDAO.allPlaces()
            .subscribe(onSuccess: { dict in
                for item in dict {
                    print2("Place: \(item.key) is nil: \(item.value == nil)")
                }
                print2("Total of places: \(dict.count)")
                
                self.debugPlaceWrappers(placeKeys: Array(dict.keys))
                
            }, onError: { error in
                print2("Load all places error")
                print2(error)
            })
            .disposed(by: bag)
    }
    
    private func debugPlaceWrappers(placeKeys: [String]) {
        PlaceWrapperDAO.load(placeKeys: placeKeys, excludeDeleted: true)
            .subscribe(onSuccess: { wrappers in
                print2("Total of wrappers: \(wrappers.count)")
            }, onError: { error in
                print2("debugPlaceWrappers error")
                print2(error)
            })
            .disposed(by: bag)
    }
    
    private func debugPlaceLocations() {
        GeoFireDAO.allPlaceLocations()
            .subscribe(onSuccess: { keys in
                print2("Total of placeLocations: \(keys.count)")
                self.debugPlaceWrappers(placeKeys: keys)
            }, onError: { error in
                print2("Load all place locations error")
                print2(error)
            })
            .disposed(by: bag)
    }
    
    private func findPlace(key: String) {
        /*
        PlaceDAO.load(placeKey: key)
            .subscribe(onNext: { place in
                print2("Load place finish [1] \(place?.name)")
            }, onError: { error in
                print2("Load place error [1]")
                print2(error)
            })
            .disposed(by: bag)
        */
        
        PlaceWrapperDAO.load(placeKey: key, excludeDeleted: true, throwErrorIfNotExists: false)
            .subscribe(onSuccess: { (wrapper: PlaceWrapper?) in
                print2("Load place finish [2] \(wrapper?.place.name)")
            }, onError: { (error: Error) in
                print2("Load place error [2]")
                print2(error)
            })
            .disposed(by: bag)
        
        PlaceWrapperDAO.load(placeKeys: [key], excludeDeleted: true)
            .subscribe(onSuccess: { wrappers in
                for wrapper in wrappers {
                    print2("Load place finish [3] \(wrapper.place.name)")
                }
            }, onError: { error in
                print2("Load place error [3]")
                print2(error)
            })
            .disposed(by: bag)
    }
    
    private func nearbySearch() {
        GooglePlaceService.instance()
            .nearbySearch(location: teutoniaCoordinates.toCLLocation(), radiusInMeters: 1000)
            .subscribe(onSuccess: { response in
                print2("Nearby search success \(response)")
                
                if let results = response?.results {
                    for item in results {
                        print2("Nearby search item: \(item.name) \(item.placeID) \(item.types)")
                    }
                }
                
            }, onError: { error in
                print2("Nearby search error \(error)")
            })
            .disposed(by: bag)
    }
    
    private func decode() {
        guard let data = handlePresenceEventJson.data(using: String.Encoding.utf8) else {
            print2("decode failed [1]")
            return
        }
        
        print2("decode proceed [1]")
        
        do {
            try JSONDecoder().decode(HandlePresenceEventResponse.self, from: data)
            print2("decode sucess]")
        } catch {
            print2("decode failed \(2) \(error)")
        }
    }
    
    private func decode2() {
        
    }
}

extension TestViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
        //return images.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.testCell, for: indexPath) as! TestCell
        cell.backgroundColor = UIColor.red
        
        if let url = S3Folder.groups.downloadURL(cloudKey: images[indexPath.row]) {
            let p0 = DownsamplingImageProcessor(size: CGSize(width: imageHeight, height: imageHeight))
            let p1 = RoundCornerImageProcessor(cornerRadius: imageHeight/2)
            
            KingfisherManager.shared.retrieveImage(
                with: url,
                options: [.processor(p0 >> p1), .cacheSerializer(FormatIndicatedCacheSerializer.png)]) { [weak self] result in
                
                guard
                    let image = result.value?.image
                else {
                    return
                }
                
                cell.testImageView.image = image
            }
        }
        
        return cell
    }
}

extension TestViewController : UITableViewDelegate {
    
}

class TestCell : UITableViewCell {
    @IBOutlet weak var testImageView: UIImageView!
}
