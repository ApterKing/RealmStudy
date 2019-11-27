//: [Previous](@previous)

import Foundation

class Book: NSObject {


    @objc func println() {
        print("fuck test")
    }

}
let book = Book()
DispatchQueue.global().async {
    print("fuck test before")
//    book.perform(#selector(book.println), on: Thread.current, with: nil, waitUntilDone: false)
    print("fuck test after")
    for i in 0...10 {
        print("fuck test after   \(i)")
    }
    print("fuck test after  delay")

    let runloop = CFRunLoopGetCurrent()
    CFRunLoopPerformBlock(runloop, CFRunLoopMode.commonModes.rawValue, {
        book.println()
    })
    CFRunLoopRun()
}
