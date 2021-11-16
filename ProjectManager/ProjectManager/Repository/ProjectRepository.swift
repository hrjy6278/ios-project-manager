//
//  ProjectRepository.swift
//  ProjectManager
//
//  Created by tae hoon park on 2021/11/15.
//

import Foundation

protocol ProjectRepositoryDelegate: AnyObject {
    func changeRepository(project: [ProjectPlan])
}

final class ProjectRepository {
    weak var delegate: ProjectRepositoryDelegate?
    private let firestore = FirestoreStorage()
    private var projects: [ProjectPlan] = [] {
        didSet {
            delegate?.changeRepository(project: projects)
        }
    }
    
    func setUp(delegate: ProjectRepositoryDelegate) {
        self.delegate = delegate
        firestore.fetch { projects in
            self.projects = projects
        }
        
        self.projects = CoreDataStack.shared.fetch().map({ project in
            ProjectPlan(id: project.id, title: project.title, detail: project.detail, date: project.date, type: project.type)
        })
    }

    func addProject(_ project: ProjectPlan) {
        projects.append(project)
        firestore.upload(project: project)
    }
    
    func removeProject(indexSet: IndexSet) {
        let index = indexSet[indexSet.startIndex]
//        CoreDataStack.shared.context.delete(projects[index])
        firestore.delete(id: projects[index].id)
        projects.remove(atOffsets: indexSet)
    }
    
    func updateProject(_ project: ProjectPlan) {
        projects.firstIndex { $0.id == project.id }.flatMap { projects[$0] = project }
        firestore.upload(project: project)
    }
}
