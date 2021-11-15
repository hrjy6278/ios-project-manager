//
//  ProjectRepository.swift
//  ProjectManager
//
//  Created by tae hoon park on 2021/11/15.
//

import Foundation

protocol ProjectRepositoryDelegate: AnyObject {
    func changeRepository(project: [Project])
}

final class ProjectRepository {
    weak var delegate: ProjectRepositoryDelegate?
    private var projects: [Project] = [] {
        didSet {
            delegate?.changeRepository(project: projects)
        }
    }
    
    func setUp(delegate: ProjectRepositoryDelegate) {
        self.delegate = delegate
        projects = CoreDataStack.shared.fetch()
    }
    
    func addProject(_ project: Project) {
        projects.append(project)
    }
    
    func removeProject(indexSet: IndexSet) {
        let index = indexSet[indexSet.startIndex]
        CoreDataStack.shared.context.delete(projects[index])
        projects.remove(atOffsets: indexSet)
    }
    
    func updateProject(_ project: Project) {
        projects.firstIndex { $0.id == project.id }.flatMap { projects[$0] = project }
    }
}
