//
//  SSZoomingScrollView.swift
//  Pods
//
//  Created by LawLincoln on 15/7/11.
//
//

import UIKit
import DACircularProgress
public class SSZoomingScrollView : UIScrollView {

    public var photo: SSPhoto!
    public var captionView: SSCaptionView!
    public var photoImageView: SSTapDetectingImageView!
    public var tapView: SSTapDetectingView!
    
    fileprivate var  progressView : DACircularProgressView!
    fileprivate weak var photoBrowser: SSImageBrowser!
    
    convenience init(aPhotoBrowser: SSImageBrowser) {
        self.init(frame: .zero)
        photoBrowser = aPhotoBrowser
        
        // Tap view for background
         tapView = SSTapDetectingView(frame:self.bounds)
         tapView.tapDelegate = self 
         tapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
         tapView.backgroundColor = UIColor.clear
         self.addSubview(tapView)
        
        // Image view
         photoImageView = SSTapDetectingImageView(frame:.zero)
         photoImageView.tapDelegate = self 
         photoImageView.backgroundColor = UIColor.clear
         self.addSubview(photoImageView)
        let screenBound = UIScreen.main.bounds
        var screenWidth = screenBound.size.width
        var screenHeight = screenBound.size.height
        let orientation = UIDevice.current.orientation
        if orientation == UIDeviceOrientation.landscapeLeft ||
            orientation == UIDeviceOrientation.landscapeRight {
                screenWidth = screenBound.size.height 
                screenHeight = screenBound.size.width 
        }
        
        // Progress view
        progressView = DACircularProgressView(frame:CGRect(x: (screenWidth-35)/2, y: (screenHeight-35)/2, width: 35.0, height: 35.0))
         progressView.progress = 0
         progressView.tag = 101 
         progressView.thicknessRatio = 0.1 
         progressView.roundedCorners = 0
         progressView.trackTintColor    = (aPhotoBrowser.trackTintColor != nil)    ? photoBrowser.trackTintColor    : UIColor(white:0.2, alpha:1)
         progressView.progressTintColor = aPhotoBrowser.progressTintColor != nil ? photoBrowser.progressTintColor : UIColor(white:1.0, alpha:1)
        self.addSubview(progressView)
        // Setup
        self.backgroundColor = UIColor.clear
        self.delegate = self 
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast 
        self.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func prepareForReuse() {
        photo = nil
        captionView?.removeFromSuperview()
        captionView = nil
        self.tag = 0
    }
    
    public func setAPhoto(aPhoto: SSPhoto) {
        photoImageView.image = nil // Release image
        if aPhoto != photo {
            photo = aPhoto
        }
        displayImage()
    }
    
    public func setProgress(progress: CGFloat, forPhoto aPhoto: SSPhoto!){
        if let url = photo?.photoURL?.absoluteString {
            if aPhoto.photoURL.absoluteString == url {
                if progressView.progress < progress {
                    progressView.setProgress(progress, animated: true)
                }
            }
        } else if aPhoto.asset.identifier == photo?.asset?.identifier {
            if progressView.progress < progress {
                progressView.setProgress(progress, animated: true)
            }
        }
        
    }
    
    
    public func displayImage() {
        if let p = photo {
            // Reset
            self.maximumZoomScale = 1
            self.minimumZoomScale = 1
            self.zoomScale = 1
            
            self.contentSize = .zero
            
            // Get image from browser as it handles ordering of fetching
            if let img = photoBrowser.imageForPhoto(photo: p) {
                // Hide ProgressView
                // progressView.alpha = 0.0f 
                progressView.removeFromSuperview()
                
                // Set image
                photoImageView.image = img
                photoImageView.isHidden = false
                
                // Setup photo frame
                var photoImageViewFrame = CGRect.zero
                photoImageViewFrame.origin = .zero
                photoImageViewFrame.size = img.size
                
                photoImageView.frame = photoImageViewFrame
                self.contentSize = photoImageViewFrame.size
                
                // Set zoom to minimum zoom
                setMaxMinZoomScalesForCurrentBounds()
            } else {
                // Hide image view
                photoImageView.isHidden = true
                
                progressView.alpha = 1.0
            }
            
            self.setNeedsLayout()
        }
    }
    
    public func displayImageFailure() {
        progressView.removeFromSuperview()
    }
    
    public func setMaxMinZoomScalesForCurrentBounds() {
        // Reset
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
        
        // fail
        if photoImageView.image == nil {
            return
        }
        
        // Sizes
        let boundsSize = self.bounds.size
        let imageSize = photoImageView.frame.size
        
        // Calculate Min
        let xScale = boundsSize.width / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = boundsSize.height / imageSize.height  // the scale needed to perfectly fit the image height-wise
        let minScale = min(xScale, yScale)                  // use minimum of these to allow the image to become fully visible
        
        // If image is smaller than the screen then ensure we show it at
        // min scale of 1
        if xScale > 1 && yScale > 1 {
            //minScale = 1.0
        }
        
        // Calculate Max
        var maxScale:CGFloat = 4.0 // Allow double scale
        // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
        // maximum zoom scale to 0.5.

            maxScale = maxScale / UIScreen.main.scale
            
            if (maxScale < minScale) {
                maxScale = minScale * 2
            }
        
        
        // Set
        self.maximumZoomScale = maxScale
        self.minimumZoomScale = minScale
        self.zoomScale = minScale
        
        // Reset position
        photoImageView.frame = CGRect(x: 0, y: 0, width:  photoImageView.frame.size.width, height: photoImageView.frame.size.height)
        self.setNeedsLayout()
    }
    
    public override func layoutSubviews() {
        // Update tap view frame
        tapView.frame = self.bounds
        
        // Super
        super.layoutSubviews()
        
        // Center the image as it becomes smaller than the size of the screen
        let boundsSize = self.bounds.size 
        var frameToCenter = photoImageView.frame
        
        // Horizontally
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2.0)
        } else {
            frameToCenter.origin.x = 0 
        }
        
        // Vertically
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2.0)
        } else {
            frameToCenter.origin.y = 0 
        }
        
        // Center
        if !photoImageView.frame.equalTo(frameToCenter) {
            photoImageView.frame = frameToCenter
        }
    }
    
}
// MARK: - UIScrollViewDelegate
extension SSZoomingScrollView: UIScrollViewDelegate {
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        photoBrowser.cancelControlHiding()
    }

    public func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        photoBrowser.cancelControlHiding()
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        photoBrowser.hideControlsAfterDelay()
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

extension SSZoomingScrollView: SSTapDetectingViewDelegate, SSTapDetectingImageViewDelegate {
    
    private func handleSingleTap(touchPoint: CGPoint) {
        let deadline = DispatchTime.now() + 0.2
        DispatchQueue.main.asyncAfter(deadline: deadline) { 
            self.photoBrowser.toggleControls()
        }
    }
    
    private func handleDoubleTap(touchPoint: CGPoint) {
    
    // Cancel any single tap handling
        NSObject.cancelPreviousPerformRequests(withTarget: photoBrowser)
    
    // Zoom
        if self.zoomScale == self.maximumZoomScale {
            self.setZoomScale(self.minimumZoomScale, animated: true)
    
        } else {
            self.zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
    
        }
    
    // Delay controls
        photoBrowser.hideControlsAfterDelay()
    }
    
    
    public func imageView(_ imageView: UIImageView, singleTapDetected touch: UITouch) {
        handleSingleTap(touchPoint: touch.location(in: imageView))
    }
    
    public func imageView(_ imageView: UIImageView, doubleTapDetected touch: UITouch) {
        handleDoubleTap(touchPoint: touch.location(in: imageView))
    }
    
    public func imageView(_ imageView: UIImageView, tripleTapDetected touch: UITouch) {
        
    }
    
    public func view(_ view: UIView, singleTapDetected touch: UITouch) {
        handleSingleTap(touchPoint: touch.location(in: view))
    }
    public func view(_ view: UIView, doubleTapDetected touch: UITouch) {
        handleDoubleTap(touchPoint: touch.location(in: view))
    }
    public func view(_ view: UIView, tripleTapDetected touch: UITouch) {
        
    }

}
