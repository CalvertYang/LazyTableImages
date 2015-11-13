//
//  AppDelegate.swift
//  LazyTableImages
//
//  Created by Calvert Yang on 11/12/15.
//  Copyright © 2015 Calvert. All rights reserved.
//

import UIKit

// the http URL used for fetching the top iOS paid apps on the App Store
let TopPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // the queue to run our "ParseOperation"
    var queue: NSOperationQueue?

    // the NSOperation driving the parsing of the RSS feed
    var parser: ParseOperation?

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let request = NSURLRequest(URL: NSURL(string: TopPaidAppsFeed)!)

        // create an session data task to obtain and the XML feed
        let sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {
            data, response, error in

            // in case we want to know the response status code
            //let httpStatusCode = (response as! NSHTTPURLResponse).statusCode

            if (error != nil) {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                    var isATSError = false
                    if #available(iOS 9.0, *) {
                        isATSError = error!.code == NSURLErrorAppTransportSecurityRequiresSecureConnection
                    }

                    if (isATSError) {
                        // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        //
                        abort()
                    } else {
                        self.handleError(error!)
                    }
                })
            } else {
                // create the queue to run our ParseOperation
                self.queue = NSOperationQueue()

                // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
                self.parser = ParseOperation(data: data!)

                self.parser!.errorHandler = { [weak self] parseError in
                    dispatch_async(dispatch_get_main_queue(), {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        self?.handleError(parseError)
                    })
                }

                self.parser!.completionBlock = { [weak self] in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if (self?.parser!.appRecordList != nil) {
                        // The completion block may execute on any thread.  Because operations
                        // involving the UI are about to be performed, make sure they execute on the main thread.
                        //
                        dispatch_async(dispatch_get_main_queue(), {
                            // The root rootViewController is the only child of the navigation
                            // controller, which is the window's rootViewController.
                            //
                            let rootViewController = (self?.window?.rootViewController as! UINavigationController).topViewController as! RootViewController

                            rootViewController.entries = self?.parser?.appRecordList

                            // tell our table view to reload its data, now that parsing has completed
                            rootViewController.tableView.reloadData()
                        })
                    }

                    // we are finished with the queue and our ParseOperation
                    self?.queue = nil
                };
                
                self.queue?.addOperation(self.parser!) // this will start the "ParseOperation"
            }
        })

        sessionTask.resume()

        // show in the status bar that network activity is starting
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func handleError(error: NSError) {
        let errorMessage = error.localizedDescription

        // alert user that our current record was deleted, and then we leave this view controller
        //
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: "Cannot Show Top Paid Apps", message: errorMessage, preferredStyle: UIAlertControllerStyle.ActionSheet)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
                // dissmissal of alert completed
            })

            alert.addAction(okAction)
            self.window!.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(title: "Cannot Show Top Paid Apps", message: errorMessage, delegate: nil, cancelButtonTitle: "OK")

            alertView.show()
        }
    }

}

