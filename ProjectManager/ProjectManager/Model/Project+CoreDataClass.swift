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
class Project: NSManagedObject, Codable {

    convenience init(id: String = UUID().uuidString, title: String, detail: String, date: Date, type: ProjectStatus) {
        self.init(context: CoreDataStack.shared.context)
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.type = type
    }
    required convenience init(from decoder: Decoder) throws {
        self.init(context: CoreDataStack.shared.context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.detail = try container.decode(String.self, forKey: .detail)
        self.date = try container.decode(Date.self, forKey: .date)
        let status = try container.decode(Int16.self, forKey: .type)
        self.type = ProjectStatus(rawValue: status)!
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.detail, forKey: .detail)
        try container.encode(self.date, forKey: .date)
        try container.encode(self.type.rawValue, forKey: .type)
    }
    enum CodingKeys: CodingKey {
        case id, title, detail, date, type
    }
}
