//
//  SSPhoto.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit
import SDWebImage
import Photos
public final class SSPhoto: NSObject {
    public var aCaption: String!
    public var photoURL: NSURL!
    public var progressUpdateBlock: SSProgressUpdateBlock!
    public var aPlaceholderImage: UIImage!
    
    fileprivate var aUnderlyingImage: UIImage!
    fileprivate var loadingInProgress: Bool!
    public var  photoPath: String!
    public var asset: PHAsset!
    public var targetSize: CGSize!
    fileprivate var requestId: PHImageRequestID!
    
    convenience public init(image: UIImage) {
        self.init()
        aUnderlyingImage = image
    }
    
    convenience public init(filePath: String) {
        self.init()
        photoPath = filePath
    }
    
    convenience public init(url: NSURL) {
        self.init()
        photoURL = url
    }
    
    convenience public init(aAsset: PHAsset, aTargetSize: CGSize! = nil) {
        self.init()
        asset = aAsset
        targetSize = aTargetSize
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "stopAllRequest"), object: nil, queue: OperationQueue.main) {[weak self] (_) -> Void in
            self?.cancelRequest()
        }
    }
    
    deinit {
        cancelRequest()
    }
    
    func cancelRequest() {
        if let id = requestId {
            PHImageManager.default().cancelImageRequest(id)
        }
    }
}
// MARK: - NSURLSessionDelegate
extension SSPhoto: URLSessionDownloadDelegate{
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }

    public func URLSession(session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingToURL location: URL) {
        let downloadedImage = UIImage(data: try! Data(contentsOf: location))
        self.aUnderlyingImage = downloadedImage
        DispatchQueue.global().async {
            self.imageLoadingComplete()
        }
    }
    public func URLSession(session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten)/CGFloat(totalBytesExpectedToWrite)
        progressUpdateBlock?(progress)
    }
}
// MARK: - Class Method
extension SSPhoto {
    
    public class func photoWithImage(image: UIImage) -> SSPhoto {
        return SSPhoto(image: image)
    }
    
    public class func photoWithFilePath(path: String) -> SSPhoto {
        return SSPhoto(filePath: path)
    }
    
    public class func photoWithURL(url: NSURL) -> SSPhoto {
        return SSPhoto(url: url)
    }
    
    public class func photosWithImages(imagesArray: [UIImage]) -> [SSPhoto] {
        var photos = [SSPhoto]()
        for image in imagesArray {
            photos.append(SSPhoto(image: image))
        }
        return photos
    }
    
    public class func photosWithFilePaths(pathsArray: [String]) -> [SSPhoto] {
        var photos = [SSPhoto]()
        for path in pathsArray {
            photos.append(SSPhoto(filePath: path))
        }
        return photos
    }
    
    public class func photosWithURLs(urlsArray: [NSURL]) -> [SSPhoto] {
        var photos = [SSPhoto]()
        for url in urlsArray {
            photos.append(SSPhoto(url: url))
        }
        return photos
    }
    
    public class func photosWithAssets(assets: [PHAsset], targetSize: CGSize! = nil) -> [SSPhoto] {
        var photos = [SSPhoto]()
        for asset in assets {
            photos.append(SSPhoto(aAsset: asset, aTargetSize: targetSize))
        }
        return photos
    }
    
}

// MARK: - SSPhotoProtocol
public func == (lhs: SSPhoto, rhs: SSPhoto) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension SSPhoto {
    
    public func underlyingImage() -> UIImage! {
        return aUnderlyingImage
    }
    public func loadUnderlyingImageAndNotify() {
        loadingInProgress = true
        if aUnderlyingImage != nil {
            imageLoadingComplete()
        }else{
            if let _ = photoPath {
                DispatchQueue.global().async {
                    self.loadImageFromFileAsync()
                }
            } else if let url = photoURL {
                let key = url.absoluteString
                
                if let cache = SDImageCache.shared().imageFromDiskCache(forKey: key) {
                    let deadline = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: deadline, execute: { 
                        self.aUnderlyingImage = cache
                        self.imageLoadingComplete()
                    })
                    return
                }
                SDWebImageDownloader.shared().downloadImage(with: url as URL, options: SDWebImageDownloaderOptions.continueInBackground, progress: {[weak self] (read, total, sdUrl) -> Void in
                    guard let sself = self else { return }
                    let progress = CGFloat(read)/CGFloat(total)
                    DispatchQueue.main.async {
                        sself.progressUpdateBlock?(progress)
                    }
                    }, completed: {[weak self] (img, data, err, flag) -> Void in
                        if let image = img, let sself = self {
                            sself.aUnderlyingImage = image
                            sself.imageLoadingComplete()
                        }
                        
                })
                
            } else if let photo = asset {
                var size = CGSize(width: CGFloat(photo.pixelWidth), height: CGFloat(photo.pixelHeight))
                if let asize = targetSize  {
                    size = asize
                }
                weak var wsekf: SSPhoto! = self
                
                let progressBlock: PHAssetImageProgressHandler = { (value, error, stop, info) -> Void in
                    DispatchQueue.main.async {
                        wsekf.progressUpdateBlock?(CGFloat(value))
                    }
                }
                DispatchQueue.global().async {
                    wsekf.requestId = photo.imageWithSize(size: size, progress: progressBlock , done: { (image) -> () in
                        DispatchQueue.main.async {
                            wsekf.aUnderlyingImage = image
                            wsekf.imageLoadingComplete()
                        }
                    })
                }
            }
            
        }
        
    }
    
    public func unloadUnderlyingImage() {
        loadingInProgress = false
        if aUnderlyingImage != nil && (photoPath != nil || photoURL != nil) {
            aUnderlyingImage = nil
        }
        cancelRequest()
    }
    
    public func caption() -> String? {
        return aCaption
    }
    
    public func placeholderImage() -> UIImage? {
        return aPlaceholderImage
    }
}


// MARK: - Async Loading
extension SSPhoto {
    func decodedImageWithImage(image:UIImage) -> UIImage? {
        if let _ = image.images {
            return image
        }
        
        let imageRef = image.cgImage
        let imageSize = CGSize(width: CGFloat(imageRef!.width), height: CGFloat(imageRef!.height))
        let imageRect = (CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = imageRef!.bitmapInfo
        
        let infoMask = bitmapInfo.intersection(CGBitmapInfo.alphaInfoMask)
        
        let alphaNone = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let alphaNoneSkipFirst = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
        let alphaNoneSkipLast = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let anyNonAlpha = infoMask == alphaNone ||
            infoMask == alphaNoneSkipFirst ||
            infoMask == alphaNoneSkipLast
        
        // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
        
        if (infoMask == alphaNone && colorSpace.numberOfComponents > 1)
        {
            // Unset the old alpha info.
            let newBitmapInfoRaw = bitmapInfo.rawValue & ~CGBitmapInfo.alphaInfoMask.rawValue
            
            // Set noneSkipFirst.
            bitmapInfo = CGBitmapInfo(rawValue: (newBitmapInfoRaw | alphaNoneSkipFirst.rawValue))
        }
            // Some PNGs tell us they have alpha but only 3 components. Odd.
        else if (!anyNonAlpha && colorSpace.numberOfComponents == 3)
        {
            // Unset the old alpha info.
            let newBitmapInfoRaw = bitmapInfo.rawValue & ~CGBitmapInfo.alphaInfoMask.rawValue
//            bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
            bitmapInfo = CGBitmapInfo(rawValue: newBitmapInfoRaw | CGImageAlphaInfo.premultipliedFirst.rawValue)
        }
        
        // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
        let context = CGContext(data: nil, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: imageRef!.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        
        // If failed, return undecompressed image
        if context == nil {
            return image
        }
        
        context?.draw(imageRef!, in: imageRect)
        guard let decompressedImageRef = context!.makeImage() else {
            return nil
        }
        
        let decompressedImage = UIImage(cgImage: decompressedImageRef, scale: image.scale, orientation: image.imageOrientation)
        return decompressedImage
    }
    
    func loadImageFromFileAsync() {
        autoreleasepool { () -> () in
            if let img = UIImage(contentsOfFile: photoPath) {
                aUnderlyingImage = img
            }else{
                if let img = decodedImageWithImage(image: aUnderlyingImage) {
                    aUnderlyingImage = img
                }
            }
            DispatchQueue.main.async(execute: { () -> Void in
                self.imageLoadingComplete()
            })
        }
    }
    
    func imageLoadingComplete() {
        loadingInProgress = false
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SSPHOTO_LOADING_DID_END_NOTIFICATION), object: self)
    }
}


public extension PHAsset {
    
    public var identifier: String {
        return NSURL(string: self.localIdentifier)?.pathComponents?[0] ?? ""
    }
    
    public func imageWithSize(size:CGSize, progress: PHAssetImageProgressHandler!, done:@escaping (UIImage!)->() ) -> PHImageRequestID! {
        let cache = SDImageCache.shared()
        let key = self.identifier+"_\(size.width)x\(size.height)"
        if let img = cache.imageFromDiskCache(forKey: key) {
            done(img)
            return nil
        }
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isSynchronous = false
        option.isNetworkAccessAllowed = true
        option.normalizedCropRect = CGRect(origin: .zero, size: size)
        option.resizeMode = .exact
        option.progressHandler = progress
        option.deliveryMode = .highQualityFormat
        option.version = .original
        
        return manager.requestImage(for: self, targetSize: size, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            if let img = result {
                cache.store(img, forKey: key, toDisk: true)
            }
            done(result)
        })
        
    }
    
    
}
