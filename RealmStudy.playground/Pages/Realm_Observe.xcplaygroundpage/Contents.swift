//: A UIKit based Playground for presenting user interface

/// 验证Realm 通知
  
import UIKit
import Realm
import RealmSwift
import PlaygroundSupport

class Animal: Object {

    @objc dynamic var id = 0
    @objc dynamic var breed: String = "asian"
    @objc dynamic var name: String?

    /// 重写此方法，如果未重写那么在调用add(xx, update: false) update必须为false
    override static func primaryKey() -> String {
        return "id"
    }

}

let realm = try! Realm()

/// 数据库任意变更监听
/// 注意所有的观察都不能够在相同Realm实例的事务中操作！！！！
let realmToken = realm.observe { (notification, realm) in
    print("Observe   Realm: notification => \(notification),  realm => \(realm)")
}

/// 单个Object的监听
/// 在监听之前如果你的Object未被Realm数据库managed，那么必须在事务中将对象写入数据库，否则会报unmanged错误
let animal = Animal()
print("Observe   Object is managed  before: \(animal.realm != nil)")
try? realm.write {
    realm.add(animal, update: true)

    let realm0 = try! Realm()
    let animal0 = Animal()
    animal0.id = Int.max
    // 相同线程的不同Realm实例事务是不能够嵌套的
//    try? realm0.write {
//        realm0.add(animal0, update: true)
//    }

    DispatchQueue.global().asyncAfter(deadline: .now(), execute: {
        let animal1 = Animal()
        animal1.id = 1
        let realm1 = try! Realm()

        // 不同的线程Realm实例事务是可以嵌套的
        try? realm1.write {
            realm1.add(animal1, update: true)
        }

        /// 注意这里即使在不同的线程不同Realm实例下，只要在一个事务中，都不能够被观察
//        _ = animal1.observe({ (change) in
//            print("Observe   Object  在不同的Realm实例的事务中观察")
//        })
    })
}
print("Observe   Object  is managed  after: \(animal.realm != nil)")
// 注意所有的观察都不能够在相同Realm实例的事务中操作！！！！
// 错误做法
//try? realm.write {
//    _ = animal.observe({ (_) in
//        // do something
//    })
//}
// 正确做法
let animatToken = animal.observe { (change) in
    switch change {
    case .error(let error):
        print("Observe  Object  error: \(String(describing: error))")
    case .change(let propertyChanges):
        for propertyChange in propertyChanges {
            print("Observe   Object  propertyChange:  name => \(propertyChange.name),  oldValue => \(propertyChange.oldValue),  newValue => \(propertyChange.newValue)")
        }
    default:
        print("Observe   Object  deleted")
    }
}
try? realm.write {
    // 请注意：当我们第一次将animal插入数据库，按理在observe->.change应该打印出oldValue，但是为什么打印出的还是为nil
    // 通过注释我们了解到，如果说我们的修改在同一个线程中oldValue的值始终为nil，这里是需要注意的
    animal.breed = "狗"
    animal.breed = "狗"
    animal.breed = "狗"
    animal.breed = "狗"  // 不管我们修改了多少次，animal通知接收到的只会也仅有一次通知，这里是为什么？还请思考
}
let animalRef = ThreadSafeReference<Animal>(to: animal)
// 我们跨线程修改再来看看，change打印出的是什么
DispatchQueue.global().async {
    let realm = try! Realm()
    guard let animalCopy = realm.resolve(animalRef) else {
        return
    }
    try? realm.write {
        animalCopy.breed = "猫"
    }
}


/// 查询结果的监听
let animal1 = Animal()
animal1.id = 1
animal1.breed = "猪"
let animal2 = Animal()
animal2.id = 2
animal2.breed = "马"
try? realm.write {
    realm.add(animal1, update: true)
    realm.add(animal2, update: true)
}
let results = realm.objects(Animal.self)
/// 注意所有的观察都不能够在相同Realm实例的事务中操作！！！！
let resultToken = results.observe { (change: RealmCollectionChange<Results<Animal>>) in
    switch change {
    case .initial(let results):
        print("Observe   Result  initial:   \(results.count)")
        break
    case .update(let results, let deletions, let insertions, let modifications):
        print("Observe   Result  update:   \(results.count)   deletions => \(deletions)  insertions => \(insertions)  modifications => \(modifications)")
    default:
        print("Observe   Result  error")
    }
}
try? realm.write {
    animal1.name = "wang"
    results.setValue("wang", forKey: "name")
}
/// 如何跨线程访问，我们在Realm_Thread这个章节已经讲述了
let resultRef = ThreadSafeReference<Results<Animal>>(to: results)
DispatchQueue.global().async {
    let realm = try! Realm()
    guard let resultsCopy = realm.resolve(resultRef) else {
        return
    }
    let animal3 = Animal()
    animal3.id = 3
    animal3.breed = "兔"
    try? realm.write {
        // 注意观察Observe   Result 的输出结果
        realm.add(animal3, update: true)
        resultsCopy.setValue("test", forKey: "name")
    }
}


/// 至此我们总结一下关于Realm实例及其对象observe的条件：
/// 1、Realm/Object/Results/List都可被观察，并且当数据发生变化不论是在哪个进程或者线程都会被通知到
/// 2、所有的观察不可以在Realm的实例事务中操作，不管被管理对象是否归属于当前Realm实例managed
/// 3、相同线程下的不同Realm实例事务操作不能够嵌套，因为这个时候即使新建Realm实例，但其还是处于transition中，不同线程下的不同Realm实例是可以嵌套的
