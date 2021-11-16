//
//  ProjectRowViewModel.swift
//  ProjectManager
//
//  Created by 박태현 on 2021/11/09.
//

import SwiftUI


protocol ProjectRowViewModelDelegate: AnyObject {
    func updateViewModel()
}

final class ProjectRowViewModel: Identifiable {
    enum Action {
        case changeType(type: ProjectStatus)
    }

    private var project: ProjectPlan
    private let repository = ProjectRepository()
    weak var delegate: ProjectRowViewModelDelegate?

    init(project: ProjectPlan) {
        self.project = project
    }

    var id: String {
        return project.id
    }

    var title: String {
        return project.title
    }

    var convertedDate: String {
        return DateFormatter.convertDate(date: project.date)
    }

    var date: Date {
        return project.date
    }

    var detail: String {
        return project.detail
    }

    var type: ProjectStatus {
        return project.type
    }

    var dateFontColor: Color {
        let calendar = Calendar.current
        switch project.type {
        case .todo, .doing:
            if calendar.compare(project.date, to: Date(), toGranularity: .day) == .orderedAscending {
                return .red
            } else {
                return .black
            }
        case .done:
            return .black
        }
    }

    var transitionType: [ProjectStatus] {
        return ProjectStatus.allCases.filter { $0 != project.type }
    }

    func action(_ action: Action) {
        switch action {
        case .changeType(let type):
            project.type = type
            repository.updateProject(project)
            delegate?.updateViewModel()
        }
    }
}
