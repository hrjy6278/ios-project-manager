//
//  Project.swift
//  ProjectManager
//
//  Created by tae hoon park on 2021/11/01.
//

import Foundation

struct ProjectPlan: Identifiable, Codable {
    let id: String
    var title: String
    var detail: String
    var date: Date
    var type: ProjectStatus

    init(id: String = UUID().uuidString,
         title: String,
         detail: String,
         date: Date,
         type: ProjectStatus) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.type = type
    }

    init(from decoder: Decoder) throws {
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

@objc
public enum ProjectStatus: Int16, CustomStringConvertible, CaseIterable {
    case todo
    case doing
    case done
    
    public var description: String {
        switch self {
        case .todo:
            return "TODO"
        case .doing:
            return "DOING"
        case .done:
            return "DONE"
        }
    }
}
