//: [Previous](@previous)

/// 介绍Realm 常用操作：创建、增删改查、数据迁移

import Foundation
import Realm
import RealmSwift

//class Chapter: Object {
//    @objc dynamic var page: Int = 0
//}

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

// 让我们通过打印控制台看看默认的相关配置，这里请注意fileURL/inMemoryIdentifier/syncConfiguration的输出，可以看出此三者为互斥的，即意味着当我们在初始化一个数据库时，只能够三选一
var configuration = Realm.Configuration.defaultConfiguration  // 默认的数据库配置
print("configuration  default  fileURL: \(configuration.fileURL?.absoluteString)   inMemoryIdentifier:  \(configuration.inMemoryIdentifier)   syncConfiguration: \(configuration.syncConfiguration)")

configuration.readOnly = true  // 下述控制台输出可知：默认的数据库可读可写，当然我们可以通过设置为仅读

// 当然我们也可以重新设置configuration一些相关属性，比如encryptionKey加密
// 我们在什么时候会使用到这个参数呢？周知在iOS8以上，设备锁定之后我们的对应文件是被保护的，这个时候你在应用后台进行数据库操作是会抛出：open() failed: Operation not permitted异常，为了能够在后台能够正常读写数据，那么我们对文件取消锁定，但是又为了保护我们的数据，我们会使用数据库提供的加密，encryptKey的作用就在于此
if let filePath = configuration.fileURL?.deletingLastPathComponent().path {
    try? FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: filePath)
}

// 注意encryptionKey必须为64-byte
//let key = Data(count: 64)
//_ = key.withUnsafeMutableBytes({ (bytes) in
//    SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
//})
configuration.encryptionKey = "abcdefghijklmnopqrestuvwxyzabcdefghijklmnopqrestuvwxyz0123456789".data(using: .utf8)!

// 在所有设置好了之后你可以将新的configration重新设置为defaultConfiguration，以备Realm()初始化（这种视情况而定）
configuration.readOnly = false
Realm.Configuration.defaultConfiguration = configuration

/// 初始化一个Realm实例，将采用默认配置
var realm = try! Realm()
//print("Basics   Realm  Schema:  \(realm.schema)")

/// add 添加/更新一个对象
let student = Student()
student.idCard = "20191120" 
try? realm.write {
    // 当update=true时，必须要求Object的subclass实现override static func primaryKey() -> String
    realm.add(student, update: true)
}
// or
realm.beginWrite()
realm.add(student, update: true)
try? realm.commitWrite()

/// 查询
let results = realm.objects(Student.self)
print("Basisc   query  results: \(results.count)")

// 还可以进行链式操作
let results0 = results.filter("idCard=%@", "20191120")

// 如果设置了主键还可以查询指定的对象
let queryStudent = realm.object(ofType: Student.self, forPrimaryKey: "20191120")
print("Basisc  query  object: \(queryStudent)")

/// 删除一个对象或者一系列对象
let student1 = Student()
student1.idCard = "20191121"
try? realm.write {
    realm.add(student1, update: true)
}
print("Basisc   delete  before  results count: \(results.count)")
let results1 = realm.objects(Student.self).filter("idCard=%@", "20191121")
try? realm.write {
    realm.delete(results1)
}
print("Basisc   delete  after  results count: \(results.count)")   // 可以看出results结果实现了自更新

// 当然你也可以
//try? realm.write {
//    realm.delete(student1)
//}

/// 多对多的使用,多对一或一对一
/// 请看Student的：books属性
let book = Book()
book.id = 1
book.name = "语文"
let book1 = Book()
book1.id = 2
book.name = "数学"
try? realm.write {
    realm.add(book, update: true)
    realm.add(book1, update: true)
    student.books.append(book)
    student.books.append(book1)
}
print("Basisc   Many-to-Many  Many-to-One:   \(student.books)")

/// inverse 关系，什么时候我们会用到这种反转的关系呢？当一个东西拥有多个关联持有者是，我们希望知道他的持有者是谁，那么这个时候就有必要
/// 请看Book的：owners 属性
DispatchQueue.global().async {
    let book = (try! Realm()).object(ofType: Book.self, forPrimaryKey: "1")
    print("Basisc   Many-to-Many  Many-to-One  inverse:   \(book.owners.first)")
}

/// 至此总结下
/// 1、在进行任何已被管理的对象操作时都必须满足 [Object].isInvalidated == false
/// 2、相同线程下的不同Realm实例事务操作不能够嵌套，因为这个时候即使新建Realm实例，但其还是处于transition中，不同线程下的不同Realm实例是可以嵌套的
/// 3、Realm不支持自增key
/// 4、Realm查询到Results仅当真正访问的时候才会加载到内存当中，故Realm查询并不支持limit，并且对数据加载到内存更友好
/// 5、Realm查询结果是自更新的，亦即意味着在任意线程更新了数据，那么都将会自动更新到查询结果


