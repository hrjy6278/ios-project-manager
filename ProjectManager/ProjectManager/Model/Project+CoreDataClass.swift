//
//  Project+CoreDataClass.swift
//  ProjectManager
//
//  Created by tae hoon park on 2021/11/15.
//
//

import Foundation
import CoreData

@objc(Project)
public class Project: NSManagedObject {
    
    convenience init(id: String = UUID().uuidString, title: String, detail: String, date: Date, type: ProjectStatus) {
        self.init(context: CoreDataStack.shared.context)
        
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.type = type
    }
}
