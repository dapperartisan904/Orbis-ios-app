//
//  OrbisPie.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import Kingfisher
import RxSwift

class OrbisPie : UIView {
    
    var groups: [Group?]?
    var points: [PointsData]? {
        didSet {
            loadImages()
        }
    }

    private var images = [String : UIImage]()
    private var tasks = [DownloadTask?]()
    private let bag = DisposeBag()
    
    deinit {
        tasks.forEach { $0?.cancel() }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawPie(rect: rect)
    }
 
    private func loadImages() {
        guard let groups = groups else { return }
        var urls = [(String, URL)]()
        let size = bounds.width
        
        groups.forEach { group in
            guard
                let group = group,
                let url = S3Folder.groups.downloadURL(cloudKey: group.imageName!)
            else {
                return
            }
            
            urls.append((group.key!, url))
        }
        
        Observable.from(urls)
            .flatMap { arg -> Observable<(String, UIImage)?> in
                let (groupKey, url) = arg
                
                return Observable<(String, UIImage)?>.create { [weak self] observer in
                    let p0 = DownsamplingImageProcessor(size: CGSize(width: 300, height: 300))
                    let p1 = RoundCornerImageProcessor(cornerRadius: size / 2)
                    
                    let task = KingfisherManager.shared.retrieveImage(
                        with: url,
                        options: [.processor(p0 >> p1), .cacheSerializer(FormatIndicatedCacheSerializer.png)]) { result in
                            guard
                                let image = result.value?.image
                            else {
                                print2("Draw segment early return [2]")
                                observer.onNext(nil)
                                observer.onCompleted()
                                return
                            }
                            
                            observer.onNext((groupKey, image))
                            observer.onCompleted()
                        }
                    
                    self?.tasks.append(task)

                    return Disposables.create {
                        task?.cancel()
                    }
                }
            }
            .toArray()
            .subscribe(onSuccess: { [weak self] result in
                print2("Load images of segments finished")
                
                guard let this = self else { return }
                
                result.forEach { tuple in
                    guard
                        let groupKey = tuple?.0,
                        let image = tuple?.1
                    else {
                        print2("Load image of segment item is nil or has incomplete data")
                        return
                    }
                    
                    this.images[groupKey] = image
                }
                
                this.setNeedsDisplay()
                
            }, onError: { error in
                print2("Load image of segment error: \(error)")
            })
            .disposed(by: bag)
    }
    
    private func drawPie(rect: CGRect) {
        if images.isEmpty {
            return
        }
        
        guard let points = points else {
            print2("Draw pie early return")
            return
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print2("Draw pie early return [2]")
            return
        }
        
        print2("Draw pie points count: \(points.count) Images count: \(images.count)")
        
        let viewCenter = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = rect.width * 0.5
        var initialAngle: CGFloat = 90

        points.forEach { point in
            guard
                let image = images[point.groupKey],
                let cgImage = image.cgImage
            else {
                print2("Draw segment early return")
                return
            }
 
            let endAngle: CGFloat = initialAngle + (360.0 * (point.percentage.cgFloat / 100.0))
            print2("Draw segment Percentage: \(point.percentage) initialAngle: \(initialAngle) endAngle: \(endAngle) radius: \(radius)")

            let path = UIBezierPath()
            path.move(to: viewCenter)
            path.addArc(
                withCenter: viewCenter,
                radius: CGFloat(radius),
                startAngle: CGFloat(initialAngle.degreesToRadians),
                endAngle: CGFloat(endAngle.degreesToRadians),
                clockwise: true)
            path.close()
           
            context.saveGState()
            context.addPath(path.cgPath)
            context.clip()
            context.translateBy(x: 0, y: radius*2)
            context.scaleBy(x: 1.0, y: -1.0)
            context.draw(cgImage, in: rect)
            context.restoreGState();

            initialAngle = endAngle
        }
    }
    
    /*
    private func drawPie(rect: CGRect) {
        guard let points = points else {
            print2("Draw pie early return")
            return
        }
    
        print2("Draw pie points count: \(points.count)")
        
        let viewCenter = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = rect.width * 0.5
        var initialAngle: CGFloat = 90
        
        points.forEach { point in
            guard
                let group = (groups?.first { $0?.key == point.groupKey } ?? nil),
                let url = S3Folder.groups.downloadURL(cloudKey: group.imageName!)
            else {
                print2("Draw segment early return [1]")
                return
            }
            
            let p0 = DownsamplingImageProcessor(size: CGSize(width: 300, height: 300))
            let p1 = RoundCornerImageProcessor(cornerRadius: rect.width / 2)
            
            let task = KingfisherManager.shared.retrieveImage(
                with: url,
                options: [.processor(p0 >> p1), .cacheSerializer(FormatIndicatedCacheSerializer.png)]) { result in
                    guard
                        let image = result.value?.image
                    else {
                        print2("Draw segment early return [2]")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let endAngle: CGFloat = initialAngle + (360.0 * (point.percentage.cgFloat / 100.0))
                        print2("Draw segment Percentage: \(point.percentage) initialAngle: \(initialAngle) endAngle: \(endAngle)")

                        let path = UIBezierPath()
                        path.move(to: viewCenter)
                        path.addArc(
                            withCenter: viewCenter,
                            radius: CGFloat(radius),
                            startAngle: CGFloat(initialAngle.degreesToRadians),
                            endAngle: CGFloat(endAngle.degreesToRadians),
                            clockwise: true)
                        path.close()
                        path.addClip()
                        
                        image.draw(in: rect)
                        initialAngle = endAngle
                    }
            }
            
            tasks.append(task)
        }
    }
    */
    
    private func drawTest(rect: CGRect) {
        // Outer circle
        UIColor.black.setFill()
        let outerPath = UIBezierPath(ovalIn: rect)
        outerPath.fill()
        
        let viewCenter = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = rect.width * 0.5
        let startAngle = 0
        let endAngle = 90
        UIColor.green.setFill()
        
        let midPath = UIBezierPath()
        midPath.move(to: viewCenter)
        
        midPath.addArc(
            withCenter: viewCenter,
            radius: CGFloat(radius),
            startAngle: CGFloat(startAngle.degreesToRadians),
            endAngle: CGFloat(endAngle.degreesToRadians),
            clockwise: true)
        
        midPath.close()
        midPath.fill()
        
        /*
         if #available(iOS 11.0, *) {
         let imageColor = UIColor(named: "follow_15")
         print2("[OrbisPie] imageColor is nil: \(imageColor == nil)")
         }
         */
        
        /*
        guard let context = UIGraphicsGetCurrentContext() else {
            print2("[OrbisPie] Graphics context is nil")
            return
        }
        */
        
        /*
         context.saveGState()
         context.setPatternPhase(CGSize(width: 500, height: 500))
         
         let imageColor = UIColor(patternImage: UIImage(named: "follow_15")!)
         imageColor.setFill()
         
         let midPath2 = UIBezierPath()
         midPath2.move(to: viewCenter)
         
         midPath2.addArc(
         withCenter: viewCenter,
         radius: CGFloat(radius),
         startAngle: CGFloat(90.degreesToRadians),
         endAngle: CGFloat(180.degreesToRadians),
         clockwise: true)
         
         midPath2.close()
         midPath2.fill()
         
         context.restoreGState()
         */
        
        //Center circle
        //UIColor.white.setFill()
        //let centerPath = UIBezierPath(ovalIn:rect.insetBy(dx: rect.width * 0.55 / 2, dy: rect.height * 0.55 / 2))
        //centerPath.fill()
        
        let image = UIImage(named: "follow_15")!
        //let cornerRadius = min(image.size.width, image.size.height) / 2.0
        //let clippingPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        //clippingPath.addClip()
        
        let midPath2 = UIBezierPath()
        midPath2.move(to: viewCenter)
        
        midPath2.addArc(
            withCenter: viewCenter,
            radius: CGFloat(radius),
            startAngle: CGFloat(90.degreesToRadians),
            endAngle: CGFloat(180.degreesToRadians),
            clockwise: true)
        
        midPath2.close()
        midPath2.addClip()
        
        // custom drawing: 2. Draw the image.
        image.draw(in: rect)
    }
}
