//
//  IconDownloader.swift
//  LazyTableImages
//
//  Created by Calvert Yang on 11/12/15.
//  Copyright © 2015 Calvert. All rights reserved.
//

import UIKit

let appIconSize: CGFloat = 48

class IconDownloader: NSObject {

    var appRecord: AppRecord?
    var completionHandler: (() -> Void)?
    var sessionTask: NSURLSessionDataTask?

    // -------------------------------------------------------------------------------
    //	startDownload
    // -------------------------------------------------------------------------------
    func startDownload() {
        let request = NSURLRequest(URL: NSURL(string: self.appRecord!.imageURLString!)!)

        // create an session data task to obtain and download the app icon
        sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {
            data, response, error in

            // in case we want to know the response status code
            //let httpStatusCode = (response as! NSHTTPURLResponse).statusCode

            if (error != nil) {
                if #available(iOS 9.0, *) {
                    if (error!.code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
                        // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        //
                        abort()
                    }
                }
            }

            NSOperationQueue.mainQueue().addOperationWithBlock({
                // Set appIcon and clear temporary data/image
                let image = UIImage(data: data!)!

                if (image.size.width != appIconSize || image.size.height != appIconSize) {
                    let itemSize = CGSizeMake(appIconSize, appIconSize)
                    UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
                    let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
                    image.drawInRect(imageRect)
                    self.appRecord!.appIcon = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                } else {
                    self.appRecord!.appIcon = image
                }

                // call our completion handler to tell our client that our icon is ready for display
                self.completionHandler?()
            })
        })

        self.sessionTask?.resume()
    }

    // -------------------------------------------------------------------------------
    //	cancelDownload
    // -------------------------------------------------------------------------------
    func cancelDownload() {
        self.sessionTask?.cancel()
        self.sessionTask = nil
    }

}
