//: [Previous](@previous)

/// 验证Realm在多线程中的操作

import Foundation
import Realm
import RealmSwift

class Book: Object {
    @objc dynamic var id = 0
    @objc dynamic var name: String?
    let owners = LinkingObjects<Student>(fromType: Student.self, property: "books")
    override static func primaryKey() -> String {
        return "id"
    }

}

class Student: Object {
    @objc dynamic var idCard: String = "20191110"
    @objc dynamic var name: String? = "wang"
    @objc dynamic var age: Int = 0
    let books = List<Book>()
    override static func primaryKey() -> String {
        return "idCard"
    }
}

let realm = try! Realm()
print("Thread  isMain: \(Thread.isMainThread)")

/// 这里我们验证一个打开的realm是否可以跨线程
/// 错误示例，Realm实例不能够跨线程
//DispatchQueue.global().async {
//    let student = Student()
//    try? realm.write {
//        realm.add(student, update: true)
//    }
//}

/// 验证初始化的对象是否可以跨线程
let student = Student()
try? realm.write {
    realm.add(student, update: true)
}
/// 错误示例，已经被Realm示例managed的对象不能够跨线程
/// 但是处于unmanaged的对象就可以当成一般的对象使用，是可以跨线程访问的，可以尝试将上述add屏蔽掉再来看看结果
//DispatchQueue.global().async {
//    let realm = try! Realm()
//    try? realm.write {
//        realm.add(student, update: true)
//    }
//}

/// 验证Results是否可以跨线程访问
let results = realm.objects(Student.self)
DispatchQueue.global().async {
    print("Thread   Results  access  before")
//    print("Thread   Results  access  \(results.count)")   // 这里会出错
    print("Thread   Results  access  after")
}

///【注意且重要】 Realm、Object、Results 或者 List 受管理实例皆受到线程的限制，这意味着它们只能够在被创建的线程上使用，否则就会抛出异常。这是 Realm 强制事务版本隔离的一种方法。否则，在不同事务版本中的线程间，通过潜在泛关系图 (potentially extensive relationship graph) 来确定何时传递对象将不可能实现。

/// 那么综上我们是否就没有办法跨线程访问Realm实例对象了呢？当然不是Realm给我们提供了一个ThreadSafeReference，来方便我们跨线程访问
/// 针对Object跨线程访问
let studentRef = ThreadSafeReference<Student>(to: student)
DispatchQueue.global().async {
    let realm = try! Realm()
    guard let studentCopy = realm.resolve(studentRef) else {
        return
    }
    print("Thread   Object  ThreadSafeReference:  \(studentCopy.idCard)")  // 可以看到结果正常输出
}

/// 针对Results跨线程访问
let resultsRef = ThreadSafeReference<Results<Student>>(to: results)
DispatchQueue.global().async {
    let realm = try! Realm()
    guard let resultsCopy = realm.resolve(resultsRef) else {
        return
    }
    print("Thread   Results  ThreadSafeReference:  \(resultsCopy.count)")  // 可以看到结果正常输出

    // 那么我们是否可以进一步访问resultsCopy中的结果呢？ 从输出结果看，答案是可以的
    print("Thread   Results  ThreadSafeReference  Object  update before: \(resultsCopy.first)")

    try? realm.write {
        resultsCopy.first?.name = "ThreadSafeReference"
    }
    print("Thread   Results  ThreadSafeReference  Object   update after: \(resultsCopy.first)")
}

/// 针对List的跨线程访问
let book = Book()
book.id = 1
book.name = "语文"
try? realm.write {
    realm.add(book, update: true)
    student.books.append(book)
}

let listRef = ThreadSafeReference<List<Book>>(to: student.books)
DispatchQueue.global().async {
    let realm0 = try! Realm()
    guard let list = realm0.resolve(listRef) else {
        return
    }
    print("Thread   List  ThreadSafeReference: \(list.first)   \(list.first?.owners)")

    // 请注意查看控制台被resolve之后的list的managed数据库实例
    print("Thread   List  ThreadSafeReference  验证当前list的管理Realm实例: \(list.realm == realm0)")


}


/// 至此，我们需要总结一下关于Realm跨线程的访问：
/// 1、Realm、Object、Results 或者 List 被管理实例皆受到线程的限制，只能够在被创建且被管理的实例线程中使用
/// 2、Object、Results、List也可以通过ThreadSafeReference来跨线程安全访问，这意味着当我们不确定某个被管理对象或者已经确定某个被管理对象在其他线程使用，开始新线程访问前我们都都可以通过线程安全引用使其能够跨线程访问
/// 3、如果一个ThreadSafeReference被一个Realm实例resolve后，那么ThreadSafeReference所指向的那个对象的管理Realm也将会变更到当前实例
