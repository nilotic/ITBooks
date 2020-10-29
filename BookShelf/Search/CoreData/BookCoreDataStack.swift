//
//  BookCoreDataStack.swift
//  BookShelf
//
//  Created by Den Jo on 2020/10/21.
//

import CoreData

final class BookCoreDataStack {
    
    // MARK: - Singleton
    static let shared = BookCoreDataStack()
        
    // This prevents others from using the default initializer for this calls
    private init() {
        storeContainer.loadPersistentStores { (persistentStoreDescription, error) in
            guard let error = error else { return }
            log(.error, error.localizedDescription)
        }
    }
            

    // MARK: - Value
    // MARK: Public
    lazy var managedContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent      = storeContainer.viewContext
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        return context
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
    /// Save a child context
    func saveContext()  {
        guard managedContext.hasChanges else { return }
        
        managedContext.perform {
            do { try self.managedContext.save() } catch { log(.error, error.localizedDescription) }
        }
    }
    
    /// Save the parent context
    func save() {
        guard storeContainer.viewContext.hasChanges else { return }
        do { try storeContainer.viewContext.save() } catch { log(.error, error.localizedDescription) }
    }
}
