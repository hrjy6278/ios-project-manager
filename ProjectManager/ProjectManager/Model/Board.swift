import UIKit

class Board {
    var title: String
    var items = [Item]()
    
    init(title: String) {
        self.title = title
    }
    
    func createItem() -> Item {
        return Item(title: "", description: "", progressStatus: "", dueDate: Int(Date().timeIntervalSince1970))
    }
    
    func addTodoItem(_ item: Item) {
        items.append(item)
    }
    
    func insertItem(at index: Int, with item: Item) {
        items.insert(item, at: index)
    }
    
    func readItems() -> [Item] {
        return items
    }
    
    func updateItem(at index: Int, with item: Item) {
       items[index].updateItem(item)
    }

    func deleteItem(at index: Int) {
        items.remove(at: index)
    }
}
