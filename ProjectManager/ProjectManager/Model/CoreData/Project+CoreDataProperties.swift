//
//  Project+CoreDataProperties.swift
//  ProjectManager
//
//  Created by tae hoon park on 2021/11/15.
//
//

import Foundation
import CoreData

extension Project {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: "Project")
    }
    
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var detail: String
    @NSManaged public var date: Date
    @NSManaged public var type: ProjectStatus
}

extension Project : Identifiable {
}
