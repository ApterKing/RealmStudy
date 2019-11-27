//
//  AppDelegate.swift
//  RealmStudy
//
//  Created by wangcong on 2019/11/13.
//  Copyright © 2019 wangcong. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class Book: Object {
    @objc dynamic var id = 0
    @objc dynamic var name: String?

    override static func primaryKey() -> String {
        return "id"
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var token: NotificationToken?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        try? XRealm.default.initialize()
        let book = Book()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let realm0 = try! Realm()
            book.id = 0
            book.name = "语文"
            try? realm0.write {
                realm0.add(book, update: true)
                XRealm.default.observe(book, { (change) in
                    print("fuck  观察变更   \(change)")
                }, { [weak self] (token, error) in
                    self?.token = token
                })
            }


            // 跨线程观察
            let queue = DispatchQueue.global() //DispatchQueue.init(label: "test")
            queue.async {
                let book1 = Book()
                let realm1 = try! Realm()
                print("观察变更，跨线程，事务： \(book1)")
                try? realm1.write {
                    realm1.add(book1, update: true)

//                    XRealm.default.observe(book1, { (change) in
//                        print("观察变更，跨线程，事务：2 \(change)")
//                    }, { (token, error) in
//                        self.token = token
//                    })
                }
                print("fuck ")
//                XRealm.default.observe(book1, { (change) in
//                    print("观察变更，跨线程，事务： \(change)")
//                }, { (token, error) in
//                    self.token = token
//                })
            }
        }


        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let book = Book()
            book.name = "化学"
            XRealm.default.add(book, true, true)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

