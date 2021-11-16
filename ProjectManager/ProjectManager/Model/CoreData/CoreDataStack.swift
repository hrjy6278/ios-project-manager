//
//  CoreDataStack.swift
//  ProjectManager
//
//  Created by tae hoon park on 2021/11/15.
//

import Foundation
import CoreData

final class CoreDataStack {
    // MARK: - Core Data stack
    static let shared = CoreDataStack()
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private let name = "CoreDataStorage"
    private lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private init() {}
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func fetch() -> [Project] {
       return try! context.fetch(Project.fetchRequest())
    }
    
    func deleteAll() {
        let dd = persistentContainer.managedObjectModel.entities
        dd.forEach { entity in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name ?? "")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            do {
                try persistentContainer.viewContext.execute(deleteRequest)
            } catch {
                print(":v")
            }
        }
    }
}
