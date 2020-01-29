//
//  Map+CircleObjects.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 17/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import RxSwift
import Kingfisher

protocol CircleOverlayRendererDelegate : class {
    func onRendererReady(renderer: CircleOverlayRenderer)
    func onRendererFadedOut(renderer: CircleOverlayRenderer)
    //func zoomIndex() -> Int
}

enum CircleAnimation {
    case changeSize, fadeOut, growAndfadeIn, spin, none
}

class CircleOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var circle: OrbisCircle
    var indexOnMapView: Int
    let initialAnimation: CircleAnimation
    
    init(circle: OrbisCircle, initialAnimation: CircleAnimation, indexOnMapView: Int) {
        let size = circle.currentSize.double * iosSizeFactor
        coordinate = circle.place.coordinates.toCLLocationCoordinate2D()
        boundingMapRect = MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize(width: size, height: size))
        self.circle = circle
        self.initialAnimation = initialAnimation
        self.indexOnMapView = indexOnMapView
    }
    
    func sizeForRenderer() -> Double {
        return boundingMapRect.width
    }
}

class CircleOverlayRenderer: MKOverlayRenderer {
    /*
        Initially used weak var, which caused some issues
        In case we cannot use strong reference because of memory issues,
        consider load image from Kingfisher cache instead
     */
    private var overlayImage: UIImage?
    
    private var size: Double
    private var lastSize: Double?
    private var rotation: CGFloat = 0.0
    private var zoomIndex: Int
    private(set) var animating = false
    private(set) var groupKey: String
    private var neverDrawn = true
    private var downloadTasks = [DownloadTask]()
    private var timer: Timer?
    private weak var delegate: CircleOverlayRendererDelegate?
    
    init(overlay: CircleOverlay, delegate: CircleOverlayRendererDelegate, zoomIndex: Int) {
        self.zoomIndex = zoomIndex
        self.delegate = delegate
        self.groupKey = overlay.circle.dominantGroup.key!

        var initialAlpha: CGFloat
        
        switch overlay.initialAnimation {
        case .growAndfadeIn:
            size = 0
            initialAlpha = 0
        case .spin:
            size = 0
            initialAlpha = 1
        default:
            size = overlay.sizeForRenderer()
            initialAlpha = Place.getOpacity(
                touchesCount: overlay.circle.touchesCount(),
                size: size,
                zoomIndex: zoomIndex,
                placeName: overlay.circle.place.name
            ).cgFloat
        }
        
        print2("[MapDebug] CircleOverlayRenderer \(overlay.circle.place.name ?? "") initialAlpha: \(initialAlpha) size: \(size)")
        
        super.init(overlay: overlay)
        
        alpha = initialAlpha
        loadImage()
    }
    
    deinit {
        //print2("CircleOverlayRenderer deinit")
        timer?.invalidate()
        timer = nil
        downloadTasks.forEach { $0.cancel() }
    }
    
    func circleOverlay() -> CircleOverlay {
        return overlay as! CircleOverlay
    }

    /*
        Using this image, renderer with alpha works well
        Using images from Kingfisher, renderer with alpha freezes the map
     */
    private func testImageWithAlpha() {
        let image = UIImage(named: "sample_car")
        overlayImage = image
        setNeedsDisplay()
        delegate?.onRendererReady(renderer: self)
    }
    
    private func loadImage() {
        let placeKey = circleOverlay().circle.place.key ?? ""
        
        //print2("[MapDebug] loadImage start placeKey: \(placeKey)")
        
        guard let url = S3Folder.groups.downloadURL(cloudKey: circleOverlay().circle.dominantGroup.imageName) else {
            print2("[MapDebug] loadImage early return [1] PlaceKey: \(placeKey)")
            return
        }
        
        //print2("[MapDebug] loadImage begin")
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let this2 = self else {
                print2("[MapDebug] loadImage early return [2] PlaceKey: \(placeKey)")
                return
            }
            
            let imageSize = 500.0
            let p0 = DownsamplingImageProcessor(size: CGSize(width: imageSize, height: imageSize))
            //let p1 = RoundCornerImageProcessor(cornerRadius: (this2.circleOverlay().sizeForRenderer()/2.0).cgFloat)
            //let p1 = RoundCornerImageProcessor(cornerRadius: (imageSize/2.0).cgFloat)
            //let options: KingfisherOptionsInfo = [.processor(p0 >> p1), .cacheSerializer(FormatIndicatedCacheSerializer.png)]
            let options: KingfisherOptionsInfo = [.processor(p0), .cacheSerializer(FormatIndicatedCacheSerializer.png)]
            
            let task = KingfisherManager.shared.retrieveImage(
                with: url,
                options: options) { [weak self] result in
                    guard
                        let this = self,
                        let retrieveResult = try? result.get()
                    else {
                        print2("[MapDebug] loadImage early return [3] PlaceKey: \(placeKey)")
                        return
                    }
                    
                    var image = retrieveResult.image
                    
                    if image.size.width != image.size.height {
                        let minSize = min(image.size.width, image.size.height).double
                        image = UIImage.cropToBounds(image: image, width: minSize, height: minSize)
                    }

                    guard let roundedImage = image.withRoundedCorners() else {
                        print2("[MapDebug] loadImage early return [4] PlaceKey: \(placeKey)")
                        return
                    }
                    
                    image = roundedImage
                    
                    //print2("[MapDebug] loadImage end placeKey: \(placeKey)")
                    this.overlayImage = image
                    
                    /*
                        guard let cgImage = image.cgImage else {
                            print2("[MapDebug] loadImage early return [4] PlaceKey: \(placeKey)")
                            return
                        }
                     
                        this.overlayImage = UIImage(cgImage: cgImage)
                        */
                    
                    mainAsync {
                        this.setNeedsDisplay()
                        this.delegate?.onRendererReady(renderer: this)
                    }
            }
            
            if let task = task {
                this2.downloadTasks.append(task)
            }
        }
    }
    
    private func mustDraw() -> Bool {
        /*
        if size == lastSize {
            return false
        }
        */
        return true
    }
    
    override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        //print2("[MapDebug] canDraw placeKey: \(circle.place.key ?? "") image is nil: \(overlayImage == nil)")
        let circle = circleOverlay().circle
        return overlayImage != nil
    }
    
    /*
        Must be careful regarding which functions is called inside this method
        For instance, changing alpha value will trigger infinite draw calls
     */
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        if !mustDraw() {
            return
        }
        
        let circle = circleOverlay().circle
        
        guard let imageReference = overlayImage?.cgImage else {
            print2("[MapDebug] draw early return [2] placeKey: \(String(describing: circle.place.key))")
            return
        }
        
        //print2("[MapDebug] renderer draw \(String(describing: circle.place.key)) size: \(size) initialAnimation: \(circleOverlay().initialAnimation)")
        
        lastSize = size
        let firstDraw = neverDrawn
        neverDrawn = false
        
        let sizeCGFloat = CGFloat(size)
        let overlayRect = overlay.boundingMapRect
        let boundingMapRect = MKMapRect(origin: overlayRect.origin, size: MKMapSize(width: size, height: size))
        var rect = self.rect(for: boundingMapRect)
        rect = rect.offsetBy(dx: -sizeCGFloat/2, dy: sizeCGFloat/2)
        
        // These two commands is because image is upside down by default
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -sizeCGFloat)
        
        /*
            Together these 3 commands perform rotation around center
            https://stackoverflow.com/questions/27030559/how-to-rotate-cgcontext-about-center
            http://www.apeth.com/iOSBook/ch15.html#_graphics_context_transforms
         */
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: rotation.degreesToRadians)
        context.translateBy(x: -rect.midX, y: -rect.midY)
        
        context.draw(imageReference, in: rect)
        context.setStrokeColor(groupStrokeColor(group: circle.dominantGroup).cgColor)
        context.setLineWidth(30.0)
        context.strokeEllipse(in: rect)
        
        if firstDraw {
            afterFirstDraw()
        }
        
        //print2("renderer.draw placekey: \(circle.place.key ?? "") rect: \(rect)")
    }

    func contains(coordinate: CLLocationCoordinate2D, touchLocaton: CGPoint) -> Bool {
        let mapPoint = MKMapPoint(coordinate)
        
        var boundingMapRect = overlay.boundingMapRect
        boundingMapRect = boundingMapRect.offsetBy(dx: -boundingMapRect.width/2, dy: -boundingMapRect.height/2)
        
        let result = boundingMapRect.contains(mapPoint)
        
        //print2("Circle contains [\(coordinate)] MapPoint: \(mapPoint) BoundingMapRect: \(overlay.boundingMapRect) TouchLocation: \(touchLocaton)")
        //print2("Circle contains [\(coordinate)] BoundingMapRect: \(overlay.boundingMapRect)")
        //print2("Circle [\(circleOverlay().circle.place.name ?? "")] Contains: \(result) [\(mapPoint)] BoundingMapRect: \(boundingMapRect)")
        
        return result
    }
 
    func animate(type: CircleAnimation, placeChange: PlaceChange, targetAlpha: Double? = nil) {
        if animating {
            return
        }
        
        let targetSize = placeChange.currentSize.double * iosSizeFactor
        print2("[MapDebug] animate from placeChange type: \(type) targetSize: \(targetSize)")
        
        switch type {
        case .changeSize:
            if size == targetSize {
                return
            }
            animateSizeAndAlpha(targetSize: targetSize, targetAlpha: targetAlpha?.cgFloat)
            
        case .fadeOut:
            fadeOut()
            
        default:
            break
        }
    }
    
    private func afterFirstDraw() {
        let animation = circleOverlay().initialAnimation
        if animation == .none {
            return
        }
        
        let overlay = circleOverlay()
        let targetSize = overlay.sizeForRenderer()
        let opacity = Place.getOpacity(
            touchesCount: overlay.circle.touchesCount(),
            size: targetSize, zoomIndex:
            zoomIndex,
            placeName: overlay.circle.place.name
        ).cgFloat
        
        switch animation {
        
        case .growAndfadeIn:
            animateSizeAndAlpha(
                targetSize: targetSize,
                targetAlpha: opacity
            )
        
        case .spin:
            animateSizeAndSpin(targetSize: targetSize, targetAlpha: opacity)
        
        default:
            break
        }
    }
    
    private func onAnimationStart() {
        //print2("onAnimationStart")
        timer?.invalidate()
        timer = nil
        animating = true
    }
    
    private func onAnimationEnd() {
        //print2("onAnimationEnd")
        timer?.invalidate()
        timer = nil
        animating = false
        
        let vm = PresenceEventViewModel.instance()
        if vm.isPlaceBeingProcessed(placeKey: circleOverlay().circle.place.key) {
            vm.clearPlaceBeingProcessed()
        }
    }
    
    func fadeOut() {
        onAnimationStart()
        
        let duration = 3.0
        let timeInterval = 0.025
        let iteractions = duration / timeInterval
        let alphaStep = (0.0 - alpha) / iteractions.cgFloat
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] (timer: Timer) in
                guard let this = self else {
                    return
                }
                
                let newAlpha = max(this.alpha + alphaStep, 0.0)
                if newAlpha == 0.0 {
                    this.onAnimationEnd()
                    this.delegate?.onRendererFadedOut(renderer: this)
                }
                
                this.alpha = newAlpha
                //this.setNeedsDisplay()
            }
        }
    }
    
    func updateAlpha(targetAlpha: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            self?.alpha = targetAlpha
            self?.setNeedsDisplay()
        }
    }
    
    private func animateSizeAndAlpha(targetSize: Double, targetAlpha: CGFloat?) {
        //print2("[MapDebug] animateSizeAndAlpha placeKey: \(String(describing: circleOverlay().circle.place.key)) targetSize: \(targetSize) targetAlpha: \(targetAlpha)")
        
        onAnimationStart()
        
        let duration = 1.5
        let timeInterval = 0.025
        let iteractions = duration / timeInterval
        let sizeStep = (targetSize - size) / iteractions
        let alphaStep: CGFloat?
        
        if let ta = targetAlpha {
            alphaStep = (ta - alpha) / iteractions.cgFloat
        }
        else {
            alphaStep = nil
        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] (timer: Timer) in
                guard let this = self else {
                    return
                }
                
                var newSize = this.size + sizeStep
                
                if sizeStep < 0 {
                    newSize = max(newSize, targetSize)
                }
                else {
                    newSize = min(newSize, targetSize)
                }

                this.size = newSize
                
                if let alphaStep = alphaStep {
                    var newAlpha = this.alpha + alphaStep
                    
                    if alphaStep < 0 {
                        newAlpha = max(newAlpha, 0.0)
                    }
                    else {
                        newAlpha = min(newAlpha, 1.0)
                    }
                
                    this.alpha = newAlpha
                }
                
                    
                this.setNeedsDisplay()
                
                if newSize == targetSize {
                    this.onAnimationEnd()
                }
                
                //print2("animateSizeAndAlpha newSize: \(newSize) targetSize: \(targetSize) sizeStep: \(sizeStep) newAlpha: \(newAlpha) targetAlpha: \(targetAlpha) alphaStep: \(alphaStep)")
            }
        }
    }
    
    private func animateSizeAndSpin(targetSize: Double, targetAlpha: CGFloat) {
        /*
            print2(
                "[MapDebug] animateSizeAndSpin placeKey: \(String(describing: circleOverlay().circle.place.key)) " +
                "targetSize: \(targetSize)" +
                "targetAlpha: \(targetAlpha)" +
                "size: \(size)"
            )
        */
        
        onAnimationStart()
        
        let duration = 1.5
        let timeInterval = 0.025
        let iteractions = duration / timeInterval
        let sizeStep = (targetSize - size) / iteractions
        let rotationTarget: CGFloat = 360.0 * 5.0
        let rotationStep = rotationTarget / iteractions.cgFloat
        let alphaStep = (targetAlpha - alpha) / iteractions.cgFloat
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] (timer: Timer) in
                guard let this = self else {
                    return
                }
                
                var newSize = this.size + sizeStep
                var newAlpha = this.alpha + alphaStep

                if sizeStep < 0 {
                    newSize = max(newSize, targetSize)
                }
                else {
                    newSize = min(newSize, targetSize)
                }
                
                if alphaStep < 0 {
                    newAlpha = max(newAlpha, 0.0)
                }
                else {
                    newAlpha = min(newAlpha, 1.0)
                }
                
                if newSize == targetSize {
                    this.onAnimationEnd()
                }
                
                this.size = newSize
                this.alpha = newAlpha
                this.rotation = min(rotationTarget, this.rotation + rotationStep)
                this.setNeedsDisplay()
                
                //print2("animateSizeAndSpin newSize: \(newSize) targetSize: \(targetSize) sizeStep: \(sizeStep) newAlpha: \(newAlpha) targetAlpha: \(targetAlpha) alphaStep: \(alphaStep)")
            }
        }
    }
    
    /*
        Only for tests
     */
    private func toggleAlpha() {
        let sign: CGFloat = alpha > 0.0 ? -1 : 1
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (timer: Timer) in
            guard let this = self else {
                return
            }
            
            var value = this.alpha + (0.1 * sign)
            value = max(0.0, value)
            value = min(1.0, value)
            
            if (sign == -1 && value == 0) || (sign == 1 && value == 1) {
                this.timer?.invalidate()
            }
            
            this.alpha = value
        }
    }
    
    /*
        Only for tests
     */
    private func toggleSize() {
        let sign: Double = size > 500.0 ? -1 : 1
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { [weak self] (timer: Timer) in
            guard let this = self else {
                return
            }
            
            var value = this.size + (25.0 * sign)
            value = max(500.0, value)
            value = min(2000.0, value)
            
            if (sign == -1 && value == 500.0) || (sign == 1 && value == 2000.0) {
                this.timer?.invalidate()
            }
            
            this.size = value
            this.setNeedsDisplay()
            
            //print2("Timer size: \(value) Sign: \(sign)")
        }
    }
    
    /*
        Only for tests
     */
    private func rotate() {
        let target = rotation + (360.0 * 2)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { [weak self] (timer: Timer) in
            guard let this = self else {
                return
            }
            
            var value = this.rotation + 10.0
            value = min(target, value)
            
            if value == target {
                this.timer?.invalidate()
            }
            
            this.rotation = value
            this.setNeedsDisplay()
            
            print2("Timer rotation: \(value) size: \(this.size)")
        }
    }
}
