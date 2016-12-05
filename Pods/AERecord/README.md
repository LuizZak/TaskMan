# AERecord
**Super awesome Core Data wrapper written in Swift (iOS, watchOS, OSX, tvOS)**

[![Language Swift 3.0](https://img.shields.io/badge/Language-Swift%203.0-orange.svg?style=flat)](https://swift.org)
[![Platforms iOS | watchOS | tvOS | OSX](https://img.shields.io/badge/Platforms-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20OS%20X-lightgray.svg?style=flat)](http://www.apple.com)
[![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](https://github.com/tadija/AERecord/blob/master/LICENSE)

[![CocoaPods Version](https://img.shields.io/cocoapods/v/AERecord.svg?style=flat)](https://cocoapods.org/pods/AERecord)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

[AECoreDataUI](https://github.com/tadija/AECoreDataUI) was previously part of **AERecord**, so you may want to check that also.

>Why do we need yet another one Core Data wrapper? You tell me!  
Inspired by many different (spoiler alert) **magical** solutions, I wanted something which combines complexity and functionality just about right.
All that boilerplate code for setting up of Core Data stack, passing the right `NSManagedObjectContext` all accross the project and different threads, not to mention that boring `NSFetchRequest` boilerplates for any kind of creating or querying the data - should be less complicated now, with **AERecord**.

## Index
- [Features](#features)
- [Usage](#usage)
    - [Create Core Data stack](#create-core-data-stack)
    - [Context operations](#context-operations)
    - [Easy Queries](#easy-queries)
        - [General](#general)
        - [Create](#create)
        - [Find first](#find-first)
        - [Find all](#find-all)
        - [Delete](#delete)
        - [Count](#count)
        - [Distinct](#distinct)
        - [Auto increment](#auto-increment)
        - [Turn managed object into fault](#turn-managed-object-into-fault)
        - [Batch update](#batch-update)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Features
- Create default or custom Core Data stack **(or more stacks)** easily accessible from everywhere
- Have **[main and background contexts](http://floriankugler.com/2013/04/29/concurrent-core-data-stack-performance-shootout/)**, always **in sync**, but don't worry about it
- [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) data in many ways with **generic one liners**
- **iCloud** support
- Covered with **unit tests**
- Covered with [docs](http://cocoadocs.org/docsets/AERecord)

## Usage

You may see [this demo project](https://github.com/tadija/AECoreDataDemo) for example.

### Create Core Data stack
Almost everything in `AERecord` is made with 'optional' parameters (which have default values if you don't specify anything).  
So you can load (create if doesn't already exist) CoreData stack like this:

```swift
do {
    try AERecord.loadCoreDataStack()
} catch {
    print(error)
}
```

or like this:

```swift
let myModel: NSManagedObjectModel = AERecord.modelFromBundle(for: MyClass.self)
let myStoreType = NSInMemoryStoreType
let myConfiguration = ...
let myStoreURL = AERecord.storeURL(for: "MyName")
let myOptions = [NSMigratePersistentStoresAutomaticallyOption : true]
do {
    try AERecord.loadCoreDataStack(managedObjectModel: myModel, storeType: myStoreType, configuration: myConfiguration, storeURL: myStoreURL, options: myOptions)
} catch {
    print(error)
}
```

or any combination of these.

If for any reason you want to completely remove your stack and start over (separate demo data stack for example) you can do it as simple as this:

```swift
do {
    try AERecord.destroyCoreDataStack() // destroy deafult stack
} catch {
    print(error)
}

do {
    let demoStoreURL = AERecord.storeURL(for: "Demo")
    try AERecord.destroyCoreDataStack(storeURL: demoStoreURL) // destroy custom stack
} catch {
    print(error)
}
```

Similarly you can delete all data from all entities (without messing with the stack) like this:

```swift
AERecord.truncateAllData()
```

### Context operations
Context for current thread (`Context.default`) is used if you don't specify any (all examples below are using `Context.default`).

```swift
// get context
AERecord.Context.main // get NSManagedObjectContext for main thread
AERecord.Context.background // get NSManagedObjectContext for background thread
AERecord.Context.default // get NSManagedObjectContext for current thread

// execute NSFetchRequest
let request = ...
let managedObjects = AERecord.execute(fetchRequest: request) // returns array of objects

// save context
AERecord.save() // save default context
AERecord.saveAndWait() // save default context and wait for save to finish

// turn managed objects into faults (you don't need this often, but sometimes you do)
let objectIDs = ...
AERecord.refreshObjects(with: [objectIDs], mergeChanges: true) // turn objects for given IDs into faults
AERecord.refreshRegisteredObjects(mergeChanges: true) // turn all registered objects into faults
```

### Easy Queries
Easy querying helpers are created as `NSManagedObject` extension.  
All queries are called on generic `NSManagedObject`, and `Context.default` is used if you don't specify any (all examples below are using `Context.default`). All finders have optional parameter for `NSSortDescriptor` which is not used in these examples.
For even more examples check out unit tests.

#### General
If you need custom `NSFetchRequest`, you can use `createPredicate(with:)` and `createFetchRequest(predicate:sortdDescriptors:)`, tweak it as you wish and execute with `AERecord`.

```swift
// create request for any entity type
let attributes = ...
let predicate = NSManagedObject.createPredicate(with: attributes)
let sortDescriptors = ...
let request = NSManagedObject.createFetchRequest(predicate: predicate, sortDescriptors: sortDescriptors)

// set some custom request properties
request.someProperty = someValue

// execute request and get array of entity objects
let managedObjects = AERecord.execute(fetchRequest: request)
```

Of course, all of the often needed requests for creating, finding, counting or deleting entities are already there, so just keep reading.

#### Create
```swift
NSManagedObject.create() // create new object

let attributes = ...
NSManagedObject.create(with: attributes) // create new object and sets it's attributes

NSManagedObject.firstOrCreate(with: "city", value: "Belgrade") // get existing object (or create new if it doesn't already exist) with given attribute

let attributes = ...
NSManagedObject.firstOrCreate(with: attributes) // get existing object (or create new if it doesn't already exist) with given attributes
```

#### Find first
```swift
NSManagedObject.first() // get first object

let predicate = ...
NSManagedObject.first(with: predicate) // get first object with predicate

NSManagedObject.first(with: "bike", value: "KTM") // get first object with given attribute name and value

let attributes = ...
NSManagedObject.first(with: attributes) // get first object with given attributes

NSManagedObject.first(orderedBy: "speed", ascending: false) // get first object ordered by given attribute name
```

#### Find all
```swift
NSManagedObject.all() // get all objects

let predicate = ...
NSManagedObject.all(with: predicate) // get all objects with predicate

NSManagedObject.all(with: "year", value: 1984) // get all objects with given attribute name and value

let attributes = ...
NSManagedObject.all(with: attributes) // get all objects with given attributes
```

#### Delete
```swift
let managedObject = ...
managedObject.delete() // delete object (call on instance)

NSManagedObject.deleteAll() // delete all objects

NSManagedObject.deleteAll(with: "fat", value: true) // delete all objects with given attribute name and value

let attributes = ...
NSManagedObject.deleteAll(with: attributes) // delete all objects with given attributes

let predicate = ...
NSManagedObject.deleteAll(with: predicate) // delete all objects with given predicate
```

#### Count
```swift
NSManagedObject.count() // count all objects

let predicate = ...
NSManagedObject.count(with: predicate) // count all objects with predicate

NSManagedObject.count(with: "selected", value: true) // count all objects with given attribute name and value

let attributes = ...
NSManagedObject.count(with: attributes) // count all objects with given attributes
```

#### Distinct
```swift
do {
    try NSManagedObject.distinctValues(for: "city") // get array of all distinct values for given attribute name
} catch {
    print(error)
}

do {
    let attributes = ["country", "city"]
    try NSManagedObject.distinctRecords(for: attributes) // get dictionary with name and values of all distinct records for multiple given attributes
} catch {
    print(error)
}
```

#### Auto Increment
If you need to have auto incremented attribute, just create one with Int type and get next ID like this:

```swift
NSManagedObject.autoIncrementedInteger(for: "myCustomAutoID") // returns next ID for given attribute of Integer type
```

#### Turn managed object into fault
`NSFetchedResultsController` is designed to watch only one entity at a time, but when there is a bit more complex UI (ex. showing data from related entities too),
you sometimes have to manually refresh this related data, which can be done by turning 'watched' entity object into fault.
This is shortcut for doing just that (`mergeChanges` parameter defaults to `true`). You can read more about turning objects into faults in Core Data documentation.

```swift
let managedObject = ...
managedObject.refresh() // turns instance of managed object into fault
```

#### Batch update
Batch updating is the 'new' feature from iOS 8. It's doing stuff directly in persistent store, so be carefull with this and read the docs first. Btw, `NSPredicate` is also optional parameter here.

```swift
NSManagedObject.batchUpdate(properties: ["timeStamp" : NSDate()]) // returns NSBatchUpdateResult?

NSManagedObject.objectsCountForBatchUpdate(properties: ["timeStamp" : NSDate()]) // returns count of updated objects

NSManagedObject.batchUpdateAndRefreshObjects(properties: ["timeStamp" : NSDate()]) // turns updated objects into faults after updating them in persistent store
```

## Requirements
- Xcode 8.0+
- iOS 8.0+

## Installation

- [Swift Package Manager](https://swift.org/package-manager/):

    ```
    .Package(url: "https://github.com/tadija/AERecord.git", majorVersion: 4)
    ```
    
- [Carthage](https://github.com/Carthage/Carthage):

    ```ogdl
    github "tadija/AERecord"
    ```

- [CocoaPods](http://cocoapods.org/):

    ```ruby
    pod 'AERecord'
    ```

## License
AERecord is released under the MIT license. See [LICENSE](LICENSE) for details.
