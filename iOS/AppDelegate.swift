//
//  AppDelegate.swift
//  iCepa
//
//  Created by Conrad Kramer on 9/25/15.
//  Copyright © 2015 Conrad Kramer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NSURLSessionTaskDelegate {
    
    var window: UIWindow?
    var session: NSURLSession?
    var completionHandler: (() -> Void)?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
    
    func wokenUpByExtension() {

    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        configuration.sharedContainerIdentifier = CPAAppGroupIdentifier
        
        self.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        self.completionHandler = completionHandler
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        self.wokenUpByExtension()
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.finishTasksAndInvalidate()
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        if let completionHandler = completionHandler {
            completionHandler()
        }
        self.session = nil
        self.completionHandler = nil
    }
}
