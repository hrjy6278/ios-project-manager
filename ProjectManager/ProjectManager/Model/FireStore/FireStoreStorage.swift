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

    func upload(project: ProjectPlan) {
        try? db.collection(path).document("\(project.id)").setData(from: project)
    }

    func fetch<T: Decodable>(completion: @escaping ([T]) -> Void) {
        db.collection(path).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot else { return }
            var datas: [T] = []
            snapshot.documents.forEach { query in
                do {
                    let data = try query.data(as: T.self)
                    if let data = data {
                        datas.append(data)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            completion(datas)
        }
    }

    func delete(id: String) {
        db.collection(path).document(id).delete()
    }
}
