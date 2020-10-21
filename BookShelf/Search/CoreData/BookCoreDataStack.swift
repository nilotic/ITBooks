//
//  BookCoreDataStack.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/21.
//

import CoreData

final class BookCoreDataStack {
    
    // MARK: - Value
    // MARK: Public
    lazy var managedContext: NSManagedObjectContext = {
        let viewContext = storeContainer.viewContext
        viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        return viewContext
    }()
    
    
    // MARK: Private
    private lazy var storeContainer: NSPersistentContainer = {
        let persistentContainer = NSPersistentContainer(name: "Books")
        
        #if UNITTEST
        let persistentStoreDescription  = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [persistentStoreDescription]
        #endif
        
        return persistentContainer
    }()
    
    
    
    // MARK: - Function
    // MARK: Public
    func loadPersistentStores(completion: ((Error?) -> Void)? = nil) {
        storeContainer.loadPersistentStores { (persistentStoreDescription, error) in
            completion?(error)
        }
    }
    
    func saveContext()  {
        guard managedContext.hasChanges else { return }
        do { try managedContext.save() } catch { log(.error, error.localizedDescription) }
    }
}

