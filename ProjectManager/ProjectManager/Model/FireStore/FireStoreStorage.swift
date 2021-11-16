//
//  FireStore.swift
//  ProjectManager
//
//  Created by 박태현 on 2021/11/16.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct FirestoreStorage {
    private let db = Firestore.firestore()
    private let path = "projectManager"

    func upload(project: Project) {
        let data = ["id": project.id,
                    "title": project.title,
                    "detail": project.detail,
                    "date": project.date,
                    "type": project.type.rawValue] as [String : Any]
        db.collection(path).document("\(project.id)").setData(data)
    }

    func delete(id: String) {
        db.collection(path).document(id).delete()
    }
}
