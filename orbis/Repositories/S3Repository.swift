//
//  S3Repository.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 20/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import AWSS3
import Photos
import Kingfisher

enum S3Folder : String {
    case
        groups = "public/groups/",
        users = "public/users/",
        posts = "public/posts/",
        chats = "public/chats/"
    
    func uploadKey(cloudKey: String, localFileType: String) -> String {
        return rawValue + cloudKey + "." + localFileType
    }
    
    func downloadKey(cloudKey: String) -> String {
        return S3Folder.bucketUrl() + rawValue + cloudKey
    }
    
    func downloadURL(cloudKey: String) -> URL? {
        return URL(string: downloadKey(cloudKey: cloudKey))
    }
    
    static func bucketUrl() -> String {
        return "https://s3.amazonaws.com/" + awsBucket + "/"
    }
}

class S3Repository : NSObject {
    
    private static var shared: S3Repository = {
        return S3Repository()
    }()
    
    static func instance() -> S3Repository {
        return S3Repository.shared
    }
    
    func upload(videoAsset: PHAsset, key: String, fileExtensionBlock: ((String?) -> Void)? = nil, errorBlock: ((Words) -> Void)? = nil) {
        print2("[S3Repository] uploadVideoAsset begin")
        
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .mediumQualityFormat
        
        manager.requestExportSession(forVideo: videoAsset, options: options, exportPreset: "AVAssetExportPresetMediumQuality") { (session, dict) in
            print2("[S3Repository] video export session dict: \(String(describing: dict))")
            
            guard let session = session else {
                print2("[S3Repository] video export session is null")
                errorBlock?(Words.errorGeneric)
                return
            }
            
            // Don't know if fixed file extension will work for all cases
            let fileExtension = ".mp4"
            var fileExtensionWithoutDot = String(fileExtension)
            fileExtensionWithoutDot.removeFirst()
            
            print2("[S3Repository] video export cloudKey: \(key) fileExtensionWithoutDot: \(fileExtensionWithoutDot)")
            
            do {
                let filename = UUID().uuidString.appending(fileExtension) // setting random file name
                let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let absoluteUrl = try fileUrl.absoluteString.appending(filename).asURL().standardizedFileURL
                
                session.outputURL = absoluteUrl
                session.outputFileType = AVFileType.mp4
                
                session.exportAsynchronously() { [weak self] in
                    print2("[S3Repository] video exportAsync finished")
                    guard let this = self else { return }
                    
                    print2("[S3Repository] video export session filename: \(filename)")
                    print2("[S3Repository] video export session fileUrl: \(fileUrl)")
                    print2("[S3Repository] video export session absoluteUrl: \(absoluteUrl)")
                    print2("[S3Repository] video export session status: \(session.status.rawValue)")
                    print2("[S3Repository] video export session progress: \(session.progress)")
                    print2("[S3Repository] video export session error: \(String(describing: session.error))")
                    print2("[S3Repository] video export session outputUrl: \(String(describing: session.outputURL))")
                    print2("[S3Repository] video export session outputFileType: \(String(describing: session.outputFileType))")
                    print2("[S3Repository] video export session tmpDir: \(String(describing: session.directoryForTemporaryFiles))")
                    
                    if let _ = session.error {
                        errorBlock?(Words.errorGeneric)
                        return
                    }

                    let uploadKey = S3Folder.posts.uploadKey(cloudKey: key, localFileType: fileExtensionWithoutDot)
                    fileExtensionBlock?(fileExtensionWithoutDot)
                    this.upload(fileURL: absoluteUrl, key: uploadKey, contentType: contentType(fileExtension: fileExtensionWithoutDot) ?? "")
                }
            } catch {
                print2("[S3Repository] video export exception \(error)")
                errorBlock?(Words.errorGeneric)
            }
        }
    }
    
    func upload(imageAssets: [PHAsset], keys: [String], compressionQuality: CGFloat = 0.9, completionBlock: (() -> Void)? = nil) {
        print2("[S3Repository] upload imageAssets begin \(hashValue)")

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        //options.isSynchronous = false
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
//        options.deliveryMode = .highQualityFormat
        
        for i in 0...imageAssets.count-1 {
            let asset = imageAssets[i]
            let key = keys[i]
            
            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: PHImageContentMode.aspectFill,
                options: options,
                resultHandler: { [weak self] (result, info) -> Void in

                print2("[S3Repository] Upload imageAsset info: \(String(describing: info))")
                    
                guard
                    let result = result,
                    let this = self
                else {
                    print2("[S3Repository] Upload imageAsset early return \(asset.burstIdentifier ?? "")")
                    return
                }
                    
                this.upload(image: result, key: key)
            })
        }
    }
    
    func upload(image: UIImage, key: String, compressionQuality: CGFloat = 0.9, completionBlock: (() -> Void)? = nil) {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            print2("[S3Repository] Upload UIImage early return")
            return
        }
    
        let cacheKey = S3Folder.bucketUrl() + key
        ImageCache.default.store(image, forKey: cacheKey)
        upload(data: data, key: key, contentType: "image/jpeg", completionBlock: completionBlock)
    
        print2("image added to cache \(cacheKey)")
    }

    private func upload(data: Data, key: String, contentType: String, completionBlock: (() -> Void)? = nil) {
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = { (task, progress) in }
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            print2("[S3Repository] Upload completionHandler error: \(String(describing: error))")
            completionBlock?()
        }
        
        AWSS3TransferUtility
            .default()
            .uploadData(
                data,
                bucket: awsBucket,
                key: key,
                contentType: contentType,
                expression: expression,
                completionHandler: completionHandler
            ).continueWith { (task) -> Any? in
                if let error = task.error {
                    print("[S3Repository] Upload Data Error: \(error.localizedDescription)")
                }
                                    
                if let uploadTask = task.result {
                    print2("[S3Repository] Upload Data Task ID: \(uploadTask.transferID)")
                }
                
                return nil
            }
    }
    
    private func upload(fileURL: URL, key: String, contentType: String) {
        print2("[S3Repository] Upload file begin FileURL: \(fileURL) key: \(key) contentType: \(contentType)")
        
        let expression = AWSS3TransferUtilityUploadExpression()
        
        expression.progressBlock = { (task, progress) in
            print2("[S3Repository] Upload file progress \(progress)")
        }
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            print2("[S3Repository] Upload completionHandler error: \(String(describing: error))")
        }
        
        AWSS3TransferUtility
            .default()
            .uploadFile(fileURL, key: key, contentType: contentType, expression: expression, completionHandler: completionHandler)
            .continueWith { (task) -> Any? in
                if let error = task.error {
                    print("[S3Repository] Upload File Error: \(error)")
                }
                
                if let uploadTask = task.result {
                    print2("[S3Repository] Upload File Task ID: \(uploadTask.transferID)")
                }
                
                return nil
        }
    }
    
    /*
        Just for test. Use Alamofire or another lib
     */
    func download() {
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {
            (task, progress) in DispatchQueue.main.async(execute: {
                // Do something e.g. Update a progress bar.
            })
        }
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        completionHandler = { (task, URL, data, error) -> Void in
            DispatchQueue.main.async(execute: {
                print2("download URL: \(String(describing: URL)) error: \(String(describing: error)) data: \(String(describing: data?.debugDescription))")
            })
        }
        
        AWSS3TransferUtility
            .default()
            .downloadData(
                fromBucket: awsBucket,
                key: "public/groups/-LFNSAtrLr67dpjKAFTs.jpeg",
                expression: expression,
                completionHandler: completionHandler)
            .continueWith { (task) -> Any? in
                if let error = task.error {
                    print2("download Error: \(error.localizedDescription)")
                }

                if let _ = task.result {
                    print2("download result")
                }

                return nil
        }
    }

}
