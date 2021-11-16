//
//  ProjectListViewModel.swift
//  ProjectManager
//
//  Created by KimJaeYoun on 2021/11/02.
//

import SwiftUI

enum Action  {
    case create(project: ProjectPlan)
    case delete(indexSet: IndexSet)
    case update(project: ProjectPlan)
}

final class ProjectListViewModel: ObservableObject{
    @Published private(set) var projectList: [ProjectRowViewModel] = []
    private let projectRepository = ProjectRepository()
    
    func onAppear() {
        projectRepository.setUp(delegate: self)
    }

    func action(_ action: Action) {
        switch action {
        case .create(let project):
            projectRepository.addProject(project)
        case .delete(let indexSet):
            projectRepository.removeProject(indexSet: indexSet)
        case .update(let project):
            projectRepository.updateProject(project)
        }
    }

    func selectedProject(from id: String?) -> ProjectRowViewModel? {
        if let id = id, let index = projectList.firstIndex(where: { $0.id == id }) {
            return projectList[index]
        }
        return nil
    }

    func filteredList(type: ProjectStatus) -> [ProjectRowViewModel] {
        return projectList.filter {
            $0.type == type
        }
    }
}

extension ProjectListViewModel: ProjectRowViewModelDelegate {
    func updateViewModel() {
        objectWillChange.send()
    }
}

extension ProjectListViewModel: ProjectRepositoryDelegate {
    func changeRepository(project: [ProjectPlan]) {
        projectList = project.map { project in
           let rowViewModel = ProjectRowViewModel(project: project)
            rowViewModel.delegate = self
            return rowViewModel
        }
    }
}
