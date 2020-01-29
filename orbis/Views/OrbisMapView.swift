//
//  OrbisMapView.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 02/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import MapKit
import RxSwift

protocol CircleClickDelegate : class {
    func onClick(placeWrapper: PlaceWrapper)
}

class OrbisMapView : MKMapView {
    
    weak var clickDelegate: CircleClickDelegate?
    private var timerBag: DisposeBag?
    
    //private(set) var currentZoomLevel: Double = 12.0
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, touch.tapCount == 1 {
            let touchLocation = touch.location(in: self)
            let locationCoordinate = self.convert(touchLocation, toCoordinateFrom: self)

            var touchedPlaces = [(PlaceWrapper, Double)]()
            
            for overlay in overlays {
                guard let renderer = renderer(for: overlay) as? CircleOverlayRenderer else {
                    print2("OrbisMapView: detecting touches early return")
                    continue
                }
                
                if renderer.contains(coordinate: locationCoordinate, touchLocaton: touchLocation) {
                    let place = renderer.circleOverlay().circle.toPlaceWrapper()
                    touchedPlaces.append((place, overlay.boundingMapRect.width))
                }
            }
            
            if let wrapper = touchedPlaces.max(by: { p0, p1 in
                return p0.1 > p1.1 }) {
                clickDelegate?.onClick(placeWrapper: wrapper.0)
            }
        }
        
        super.touchesEnded(touches, with: event)
    }

    override func addOverlay(_ overlay: MKOverlay) {
        /*
        if let _ = findOverlayWithSameKey(overlay: overlay) {
            print2("Panic!!! overlay already exists")
        }
        */
        
        super.addOverlay(overlay)
        //reorderOverlays(becauseOfOverlay: overlay)
    }
    
    private func findOverlayWithSameKey(overlay: MKOverlay) -> CircleOverlay? {
        guard let circleOverlay = overlay as? CircleOverlay else {
            return nil
        }
        
        for obj in overlays {
            guard let otherOverlay = obj as? CircleOverlay else { continue }
            if otherOverlay.circle.place.key == circleOverlay.circle.place.key {
                return otherOverlay
            }
        }
        
        return nil
    }
    
    func startReorderTimer() {
        stopReorderTimer()
        timerBag = DisposeBag()
        
        Observable<NSInteger>.interval(10.0, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] sec in
                print2("Executing reorder timer sec: \(sec)")
                guard let this = self else { return }
                this.reorderVisibleOverlays()
            })
            .disposed(by: timerBag!)
    }
    
    func stopReorderTimer() {
        timerBag = nil
    }
    
    // annotations(in: visibleMapRect) is empty, even MKOverlay inherits from MKAnnotation
    func visibleAnnotations() -> [MKAnnotation] {
        return annotations(in: visibleMapRect).map { obj -> MKAnnotation in return obj as! MKAnnotation }
    }
    
    func visibleOverlays() -> [MKOverlay] {
        //return visibleAnnotations().filter { $0 is MKOverlay }.map { $0 as! MKOverlay }
        return overlays.filter { $0.intersects?(visibleMapRect) ?? false }
    }
    
    private func reorderVisibleOverlays() {
        let vOverlays = visibleOverlays()
        print2("[Reorder circles] visibleOverlays count: \(vOverlays.count) allOverlays count: \(overlays.count)")
        
        overlays.forEach { overlay in
            reorderOverlays(becauseOfOverlay: overlay, visibleOverlays: overlays)
        }
    }
    
    private func reorderOverlays(becauseOfOverlay overlay: MKOverlay, visibleOverlays: [MKOverlay]) {
        guard let circleOverlay = overlay as? CircleOverlay else {
            return
        }

        let circle = circleOverlay.circle
        
        var debug = false
        var debug2 = false

        if  circle.place.key == "-LWW7uCKZqIKVu9GQLAl" ||
            circle.place.key == "4f7ef104bf346961448229c34956ca3e" {
            debug = true
        }

        if debug {
            print2("[Reorder circles] CurrentMillis: \(CACurrentMediaTime()) because of \(String(describing: circle.place.key)) \(String(describing: circle.place.name))")
        }
        
        for otherOverlay in visibleOverlays {
            guard
                let otherCircleOverlay = otherOverlay as? CircleOverlay,
                otherCircleOverlay.circle.place.key != circleOverlay.circle.place.key
            else {
                continue
            }
            
            if  otherCircleOverlay.circle.place.key == "-LWW7uCKZqIKVu9GQLAl" ||
                otherCircleOverlay.circle.place.key == "4f7ef104bf346961448229c34956ca3e" {
                debug2 = true
                //print2("[Reorder circles] debug2 \(otherCircleOverlay.circle.place.key ?? "") \(otherCircleOverlay.circle.place.name ?? "")")
            }
            
            /*
                if debug && debug2 {
                    print2("[Reorder circles] rect1[\(circle.place.name ?? "")]: \(overlay.boundingMapRect) rect2[\(otherCircleOverlay.circle.place.name ?? "")]: \(otherOverlay.boundingMapRect)")
                }
              */
 
            if otherCircleOverlay.boundingMapRect.intersects(circleOverlay.boundingMapRect.insetBy(dx: 2000, dy: 2000)) {
                let otherCircle = otherCircleOverlay.circle
                
                let size0 = otherCircleOverlay.circle.finalSize
                let size1 = circleOverlay.circle.finalSize
                let index0 = otherCircleOverlay.indexOnMapView
                let index1 = circleOverlay.indexOnMapView
                
                if debug {
                    print2("[Reorder circles] intersection item1: \(circle.place.name ?? "") size: \(size1) indexOnMap: \(index1)")
                    print2("[Reorder circles] intersection item2: \(otherCircle.place.name ?? "") size: \(size0) indexOnMap: \(index0)")
                }
                
                if (size0 <= size1 && index0 < index1) || (size0 > size1 && index0 > index1) {
                    otherCircleOverlay.indexOnMapView = index1
                    circleOverlay.indexOnMapView = index0
                    exchangeOverlay(otherCircleOverlay, with: circleOverlay)
                    
                    if debug {
                        print2("[Reorder circles] \(otherCircleOverlay.circle.place.name ?? "") intersects with \(circleOverlay.circle.place.name ?? "") sizes: \(otherCircleOverlay.circle.finalSize) \(circleOverlay.circle.finalSize) exchanging")
                    }
                }
            }
        }
    }
    
    func updateOpacity(zoomIndex: Int) {
        for overlay in overlays {
            guard let circleOverlay = overlay as? CircleOverlay else {
                return
            }
            
            let alpha = Place.getOpacity(
                touchesCount: circleOverlay.circle.touchesCount(),
                size: circleOverlay.circle.finalSize.double,
                zoomIndex: zoomIndex,
                placeName: ""
            )
            
            (renderer(for: overlay) as? CircleOverlayRenderer)?.updateAlpha(targetAlpha: alpha.cgFloat)
        }
    }
    
    func zoomOut() {
        //setCenterCoordinate(region.center, withZoomLevel: currentZoomLevel - 1, animated: true)
        
        let latitudeDelta = region.span.latitudeDelta*2
        let longitudeDelta = region.span.longitudeDelta*2
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region2 = MKCoordinateRegion(center: region.center, span: span)
        setRegion(region2, animated: true)
        //currentZoomLevel -= 1
        //print2("ZoomOut LatitudeDelta: \(latitudeDelta) LongitudeDelta: \(longitudeDelta) CurrentZoomLevel: \(currentZoomLevel)")
    }
    
    func zoomIn() {
        if currentZoomLevel >= 18 {
            return
        }
        
        //setCenterCoordinate(region.center, withZoomLevel: currentZoomLevel + 1, animated: true)
        
        let latitudeDelta = region.span.latitudeDelta*0.5
        let longitudeDelta = region.span.longitudeDelta*0.5
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region2 = MKCoordinateRegion(center: region.center, span: span)
        setRegion(region2, animated: true)
        //currentZoomLevel += 1
        print2("ZoomIn LatitudeDelta: \(latitudeDelta) LongitudeDelta: \(longitudeDelta) CurrentZoomLevel: \(currentZoomLevel)")
    }
}
