# 📅 프로젝트 매니저 (Project Manager)

- **팀 구성원 : YesCoach(YesCoach), Jiss(hrjy6278), 산체스(sanches37)**
- **프로젝트 기간 : 2021.10.25 ~ 2021.11.19 (4주)**

## 목차

1. **[기능구현](#i-기능-구현)**
2. **[이를 위한 설계](#ii-이를-위한-설계)**
3. **[Trouble Shooting](#iii-트러블-슈팅)**
4. **[아쉽거나 해결하지 못한 부분](#iv-해결하지-못한-문제)**
5. **[관련 학습내용](#v-관련학습-내용)**

<br>
<br>

## I. 기능 구현

![Simulator Screen Recording - iPad mini (6th generation) - 2021-11-22 at 21 09 28](https://user-images.githubusercontent.com/71247008/144963118-367434b7-b6ab-4c98-975b-e6e632025fad.gif)



- **Swift UI** 를 사용한 UI 구현
- **MVVM** 아키텍처 사용
- **Core Data**  를 활용한 로컬 캐시 구현
- **Firebase FireStore** 를 이용한 서버 DB 구현
- **Repository** 의 변경사항을 Delegate로 처리

---
<br>
<br>
<br>

## II. 이를 위한 설계

### UML

![ProjectManager UML drawio](https://user-images.githubusercontent.com/71247008/144963093-f1aa082a-0086-4308-94c0-ee1b2be08540.png)

### 로컬, 리모트 동기화 시퀀스 다이어그램

![sequence diagram](https://user-images.githubusercontent.com/71247008/144963241-1fc458e4-5380-4d69-8ebb-620700b8daeb.png)
<br>
<br>
<br>

---


### 1. SwiftUI 를 이용한 설계

- 선언형 UI인 SwiftUI를 사용하여 UI를 구현하였다.
UIKit과는 다른, 새로운 SwiftUI를 공부하고, 적용하였다.
    
    ```swift
    struct ProjectListView: View {
        @EnvironmentObject var projectListViewModel: ProjectListViewModel
        let type: ProjectStatus
        var body: some View {
            let projectList = projectListViewModel.filteredList(type: type)
            VStack {
                HStack {
                    Text(type.description)
                        .padding(.leading)
                    Text(projectList.count.description)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle())
                    Spacer()
                }
                .font(.title)
                .foregroundColor(.black)
                List {
                    ForEach(projectList) { todo in
                            ProjectRowView(viewModel: todo)
                        }
                        .onDelete { indexSet in projectListViewModel.action(
                            .delete(indexSet: indexSet))
                        }
                 }
                .listStyle(.plain)
            }
            .onAppear {
                projectListViewModel.onAppear()
            }
        }
    } 
    ```
   
---

<br>
<br>
<br>


### 2.MVVM 아키텍처를 사용하여 프로젝트 진행

- SwiftUI가 MVVM과 잘 어울린다는 글을 보고 MVVM 패턴을 적용시켰다.
- View는 Model을 모르고, ViewModel에 View에 보여질 Model 데이터를 가지게 된다.
- View의 User Interaction(Input)은 열거형으로 정의하였다.
- Output은 메서드로 정의하였다.
- 각 List Row에 해당하는 ProjectRowViewModel을 구현하였다

```swift

//리스트의 뷰모델 
final class ProjectListViewModel: ObservableObject{
//Input
  enum Action  {
      case create(project: ProjectPlan)
      case delete(indexSet: IndexSet)
      case update(project: ProjectPlan)
  }
		
  @Published private var projectList: [ProjectRowViewModel] = []

  //Repository
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

//Output
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
```

```swift
final class ProjectRowViewModel: Identifiable {
		//Model
    private var project: ProjectPlan
		//Repository
    private let repository = ProjectRepository()
    weak var delegate: ProjectRowViewModelDelegate?
		
    init(project: ProjectPlan) {
        self.project = project
    }

//Input
    enum Action {
        case changeType(type: ProjectStatus)
    }

    func action(_ action: Action) {
        switch action {
        case .changeType(let type):
            project.type = type
            repository.updateProject(project)
            delegate?.updateViewModel()
        }
    }

//Output
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
}
```

---

### 3. 로컬, 리모트 DB 구현을 위해 Core Data, Firestore 적용

- 로컬 DB를 캐싱하고 관리하기 위해 Core Data를 프로젝트에 적용하였다.
    - 코어 데이터로 `Project` 엔티티를 생성하고, 모델의 attribute들을 각각 추가하였다.
        - type 프로퍼티는 커스텀 타입이므로 이를 코어 데이터로 저장하기 위해 Integer16 타입으로 설정.
- 리모트 DB를 관리할 수 있도록 Firestore를 프로젝트에 적용하였다.

---

### 4. 레포지토리 패턴

- 로컬 DB인지 리모트 DB인지와 관계 없이 동일한 인터페이스로 데이터에 접속할 수 있도록 하기 위해 레포지토리 패턴 도입.
- 어떤 데이터를 가져올지는 레포지토리의 몫이며 뷰 모델은 레포지토리가 보내주는 데이터만 받으면 된다.

```swift
protocol ProjectRepositoryDelegate: AnyObject {
    func changeRepository(project: [ProjectPlan])
}

//레포지토리 클래스 생성
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
        self.projects = CoreDataStack.shared.fetch().map { project in
            ProjectPlan(id: project.id, title: project.title, detail: project.detail, date: project.date, type: project.type)
        }
    }

    func addProject(_ project: ProjectPlan) {
        projects.append(project)
        firestore.upload(project: project)
    }
    
    func removeProject(indexSet: IndexSet) {
        let index = indexSet[indexSet.startIndex]
        firestore.delete(id: projects[index].id)
        projects.remove(atOffsets: indexSet)
    }
    
    func updateProject(_ project: ProjectPlan) {
        projects.firstIndex { $0.id == project.id }.flatMap { projects[$0] = project }
        firestore.upload(project: project)
    }
}


//ViewModel
//ViewModel에서는 레포지토리를 소유하고 있다. CRUD의 기능은 레포지토리에게 시킨다.
final class ProjectListViewModel: ObservableObject{
    @Published private(set) var projectList: [ProjectRowViewModel] = []
    private let projectRepository = ProjectRepository()
    
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
    
```

---

<br>
<br>
<br>


## III. 트러블 슈팅

1. Target Membership 관련 이슈
    
    타겟 추가 후 `SceneDelegate`에서 `ContentView`를 접근해야되는데 인식하지 못했음.
    (Can't not found ContentView)
    

→ View의 파일에서 Target Membership 체크하고 나서야 접근할 수 있었다.

![타켓멤버쉽 에러](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/ad9760a6-b12a-4352-9b16-11aafe9d867a/%EC%8A%A4%ED%81%AC%EB%A6%B0%EC%83%B7_2021-11-01_%EC%98%A4%ED%9B%84_9.02.33.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211126%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211126T084803Z&X-Amz-Expires=86400&X-Amz-Signature=d785e3d55443f1f0ae5a555c4e00cb4ac2132ba104dee4f7859ce2137b5adfb4&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22%25EC%258A%25A4%25ED%2581%25AC%25EB%25A6%25B0%25EC%2583%25B7%25202021-11-01%2520%25EC%2598%25A4%25ED%259B%2584%25209.02.33.png%22&x-id=GetObject)
---

1. 네비게이션 좌측 Plus버튼을 눌러도 Sheet View 가 안뜨는 문제
    
    ```swift
    // 수정 코드
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
          Button {
              isPresented.toggle()
          } label: {
              Image(systemName: "plus")
          }.sheet(isPresented: $isPresented) {
              NewTodoView()
          }
    }
     // isPresented 값이 true 로 바뀌고 적용을 하도록 수정함
    ```
    
    ```swift
    // 이전 코드
    
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isPresented.toggle()
    						sheet(isPresented: $isPresented) {
                NewTodoView()
                }
            } label: {
                Image(systemName: "plus")
             }
    
    // 버튼 내부에서 sheet를 호출해서 문제가 됨
    
    ```
    
    - Swift UI는 선언형 프로그래밍 방식이라, 모든 State에 따라 뷰가 그려져야한다.
    우리의 사고방식은 기존 UIKit을 썼을때 처럼 Button 을 누르면 어떤 뷰를 띄워줘야한다는 생각에
     Button의 Action안에 sheet View를 생성하였다.
    이는 잘못된 방법이란걸 깨닫고 **선언형 방법**으로 코드를 수정하였다.
    
    ---
    
2. **Published 프로퍼티가 동시에 변경되면서** 뷰를 순환적으로 다시 그리는 이슈(CPU 오버헤딩)
    
    ```swift
    final class ToDoListViewModel: ObservableObject{
        @Published private(set) var toDoList: [Todo] = []
        @Published private(set) var count: [SortType: Int] = [.toDo: 0, .doing: 0, .done: 0]
    
        func action(_ action: Action) {
            switch action {
            case .create(let todo):
                toDoList.append(todo)
            case .delete(let indexSet):
                toDoList.remove(atOffsets: indexSet)
            case .update(let todo):
                toDoList.firstIndex { $0.id == todo.id }.flatMap { toDoList[$0] = todo }
            case .changeType(let id, let type):
                toDoList.firstIndex { $0.id == id }.flatMap { toDoList[$0].type = type }
            }
        }
    
        func fetchList(type: SortType) -> [Todo] {
            let list = toDoList.filter {
                $0.type == type
            }
            **count[type] = list.count**
            return list
        }
    ```
    
    1. fetchList를 호출
    2. count[type]에 새로운 변수 할당 → @Published var count 값 변경 → 뷰 다시 그리세여
    3. 다시 fetchList가 호출
    4.  반복...
        
        ![스크린샷 2021-11-05 21.09.01.png](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/755aee0b-1269-47a2-94fc-b0bd8963f1e0/%E1%84%89%E1%85%B3%E1%84%8F%E1%85%B3%E1%84%85%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A3%E1%86%BA_2021-11-05_21.09.01.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211126%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211126T085022Z&X-Amz-Expires=86400&X-Amz-Signature=58ce3b625560ea64ebf772d5ce816cbf6f51875681fa4e603116b43967c917a0&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA%25202021-11-05%252021.09.01.png%22&x-id=GetObject)
        
    
    → 앱 실행시 화면이 계속 그려지는 (한무반복) 상황 발생 → CPU 100% 오버헤드 발생
    
    > Published 프로퍼티 사용에 유념.
    한 메소드에서 복수의 Published 프로퍼티가 변경되면, 뷰는 계속 순환하여 그려진다.
    > 

---

<br>
<br>
<br>

1. 모달뷰를 키보드가 가리는 문제
    
    ![Simulator Screen Recording - iPad mini (6th generation) - 2021-11-05 at 16.36.04.gif](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/dff7819a-2304-44b8-8bab-c985846dfdcc/Simulator_Screen_Recording_-_iPad_mini_%286th_generation%29_-_2021-11-05_at_16.36.04.gif?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211126%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211126T085045Z&X-Amz-Expires=86400&X-Amz-Signature=e95f2c91284db16308863480340409418cbea77a76f428f0be418789060c15c2&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Simulator%2520Screen%2520Recording%2520-%2520iPad%2520mini%2520%286th%2520generation%29%2520-%25202021-11-05%2520at%252016.36.04.gif%22&x-id=GetObject)
    
    ```swift
    var body: some View {
                NavigationView {
                    **GeometryReader { geo in**
                    VStack {
                        ScrollView {
                            TextField("Title", text: $title)
                                .textFieldStyle(.roundedBorder)
                            DatePicker("Title",
                                       selection: $date,
                                       displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            
                            **TextEditor(text: $description)**
                                .frame(width: geo.size.width,
    																	 height: geo.size.height * 0.65,
    																	 alignment: .center)
                        }
                        
                    }
                }
    ```
    
    1. 모달뷰에 키보드 자판이 생겼을 때 TextEditor 를 가리는 문제가 발생했다.
    2. TextField, DatePicker, TextEditor 를 ScrollView 로 감싸서 스크롤이 되도록하려고 했는데, TextEditor 가 화면에 보이지 않았다.
    3. TextEditor 의 사이즈를 지정해주기 위해 GeometryReader 를 사용해서 상위뷰와 관련한 높이를 지정해줘서 스크롤시 문제가 되지 않게 하였다.
    4. 해결하지 못한 문제는 GeometryReader 를 ScrollView 에 넣었을 때는 높이값이 엄청 작게 나오는 문제가 발생했다.
2. [Foreach](https://developer.apple.com/documentation/swiftui/foreach)와 [foreach](https://developer.apple.com/documentation/swift/array/1689783-foreach)의 차이
    
    Foreach는 식별된 데이터의 기본 컬렉션에서 요구에 따른 뷰를 계산하는 Structure.
    
    foreach는 시퀀스의 각 요소에 대해 지정된 클로저를 for-in 반복문의 순서로 호출한다.
    
    수정 전
    
    ![스크린샷 2021-11-05 오후 8.33.18.png](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/ff9baf18-3753-44c1-91f1-522a9128608d/%EC%8A%A4%ED%81%AC%EB%A6%B0%EC%83%B7_2021-11-05_%EC%98%A4%ED%9B%84_8.33.18.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211126%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211126T085108Z&X-Amz-Expires=86400&X-Amz-Signature=6356fd93a7062ca2f3c83c4968989d7bc5bea7ffdc4e3edf80b157d31df7be1b&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22%25EC%258A%25A4%25ED%2581%25AC%25EB%25A6%25B0%25EC%2583%25B7%25202021-11-05%2520%25EC%2598%25A4%25ED%259B%2584%25208.33.18.png%22&x-id=GetObject)
    
    수정 후
    
    ![스크린샷 2021-11-05 오후 8.42.07.png](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/740d9825-b222-4796-9e00-ff65c16f0502/%EC%8A%A4%ED%81%AC%EB%A6%B0%EC%83%B7_2021-11-05_%EC%98%A4%ED%9B%84_8.42.07.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211126%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211126T085124Z&X-Amz-Expires=86400&X-Amz-Signature=0ed09552ead160950d643e6d3f1b627f0206df46ec858ac062c7274132bc6c33&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22%25EC%258A%25A4%25ED%2581%25AC%25EB%25A6%25B0%25EC%2583%25B7%25202021-11-05%2520%25EC%2598%25A4%25ED%259B%2584%25208.42.07.png%22&x-id=GetObject)
    
    LongPressed 로 popover 를 띄울 때, enum ProjectStatus 타입의 todo, doing, done 중 filter 를 이용하여 LongPressed 되지 않은 타입들을 뽑아낸 뒤 forEach를 사용하여 moveButton을 호출하려고 하였는데 오류가 발생했다.
    
    뷰를 그려주는 행위라 뷰를 그릴 때 사용하는 Foreach 를 사용하여 해결하였다.
    
    ---
    
    <br>
    <br>
    <br>
    
3. Cell 클릭 후 내용 수정을 했을 때 수정이 되지 않은 이슈
    
    ```swift
    struct ModalView: View {
        @EnvironmentObject var todoListViewModel: ProjectListViewModel
        @Binding var isDone: Bool
    		 ...
        let modalViewType: ModalType
        let currentProject: Project? // **#1**
    
    	.....
    }
    
    struct ProjectRowView: View {
        @EnvironmentObject var projectListViewModel: ProjectListViewModel
        @State private var isModalViewPresented: Bool = false
        @State private var isLongPressed: Bool = false
        **var project: Project**
    
        var body: some View {
    
    			....
    		 }.sheet(isPresented: $isModalViewPresented) {
                    ModalView(isDone: $isModalViewPresented,
                              modalViewType: .edit,
                              **currentProject: project) // #2**
                }
    }
    
    --------------------------------------------------------------------------
   // 수정 전 customTrailingButton
    extension ModalView {
    		private var customTrailingButton: some View {
            Button {
                if modalViewType == .add {
                    todoListViewModel.action(
                        .create(project: Project(title: title,
                                                 description: description,
                                                 date: date,
                                                 type: .todo)))
                } else if isEdit && modalViewType == .edit,
                          let currentProject = currentProject {
                    **todoListViewModel.action(
                        .update(project: Project(project: currentProject))) 
    													// #3**
                }
                isDone = false
            } label: {
                Text("Done")
            }
        }
    }
    -----------------------------------------------------------------------
    
    //수정 후 customTrailingButton
    extension ModalView {
    		private var customTrailingButton: some View {
            Button {
                if modalViewType == .add {
                    todoListViewModel.action(
                        .create(project: Project(title: title,
                                                 description: description,
                                                 date: date,
                                                 type: .todo)))
                } else if isEdit && modalViewType == .edit,
                          let currentProject = currentProject {
                    todoListViewModel.action(
                        .update(project: Project(id: currentProject.id,
                                                 title: title,
                                                 description: description,
                                                 date: date,
                                                 type: currentProject.type)))
    															// #4**
                }
                isDone = false
            } label: {
                Text("Done")
            }
        }
    }
    ---------------------------------------------------------------------------
    
    final class ProjectListViewModel: ObservableObject{
        @Published private(set) var projectList: [Project] = []
    
    			func action(_ action: Action) {
            switch action {
    					......
                  case .update(let project):
                projectList.firstIndex { $0.id == project.id }
    							.flatMap { projectList[$0] = project } // #5
            }
    ```

  1.  ModalView 에서 Model 를 프로퍼티로 가지고 있어서 ModalView 를 호출 할 때 `currentProject` 를 초기화해야 된다.
  2. ProjectRowView 에서 ModalView 를 호출할 때 **`var project: Project`** 를 주입해주고 있기 때문에 
  클릭한 Cell 의 Project 를 ModalView가 알고 있다.
  3. 수정 전 customTrailingButton 에서는 currentProject 를 viewModel 로 전달해서 값을 수정하려고 했는데 currentProject 값이 모달 화면이 뜰 때의 값이라 입력한 값을 전달해주기 위해 코드를 수정했다.
  4. 수정 후 title, description, date 의 값을 우리가 입력한 값으로 viewModel 에 넘겨주었다.
  이때  우리가 원하는 배열의 index 를 찾기 위해 **`currentProject.id`** 를 viewModel 에 넘겨주었다.
  5. **`currentProject.id`** 로 index 를 찾아서  배열의 원하는 index 의 내용을 수정했다.
  
  ---
    
1. **`CoreData ManagedObject`** 을 프로젝트의 모델타입으로 사용했었는데 리모트 저장소의 데이터를 디코딩해 올 때마다 로컬 저장소에 여러번 저장되는 문제가 발생하여, 별개의 모델 타입을 생성하여 리모트저장소로부터 데이터를 받아오도록 수정하였다.
    
    이전 **`CoreData ManagedObject`** 을 사용한 코드
    
    ```swift
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
    ```
    
    별도의 모델타입을 만든 코드
    
    ```swift
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
    ```
    
---
<br>
<br>

## IV. 해결하지 못한 문제

1. 로컬 과 리모트의 동기화 시점를 적용하는것에 대해 많은 시간이 있질 않아, 해보다가 포기하였다.
    
    시퀀스 다이어 그램을 그려놓았으나, 실제로 해보니깐 이것저것 신경써야 될 게 많아 시간적 여유가 부족하였다.
    
    ![Untitled Diagram.drawio.png](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/13519511-6d7e-4cc9-91c9-2c36bbea7345/Untitled_Diagram.drawio.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211126%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211126T092632Z&X-Amz-Expires=86400&X-Amz-Signature=f3353cfade9ec11e4429bee73cd8793e7f23cf3ef86f58afca5b27ac2b5e5f52&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Untitled%2520Diagram.drawio.png%22&x-id=GetObject)
    

---

1. List Cell 간격
    
    `Swift UI`의 `List View` 를 사용했을때 `Cell`의 간격을 줄 수가 없었다. 이 부분을 해결하지 못했다.
    
    ![팀원들과 함께한 프로젝트](https://user-images.githubusercontent.com/71247008/144963352-7d7ff296-cbda-4b7a-9016-7d915e64bb70.png)
    
    팀원들과 함께한 프로젝트
    
    - 다른 캠퍼들의 얘기를 들어보면 List는 Cell간의 거리를 조절할 수 없다는 얘기가 많이 나왔다.
    이에따라 `Cell`간의 간격을 주려면 `LazyVStack`을 써볼 수 있을 것 같다. 
    `Stack`이기때문에  `Spacing`을 줄수 있다.
    
    ---
    

3. 할일 리스트의 갯수를 세는 부분에 연산과정이 많은 문제.

- 현재  `View`에서 `ViewModel`에게 그릴 `Model`을 요청하게 된다.
    
    **할일, 하는중, 완료** 이 세가지 `case`를 가진 `Enum`을 만들어 각각의 `List`를 뽑아 올 수 있게끔하였다. 
    
    ```swift
    func filteredList(type: ProjectStatus) -> [Project] {
            return projectList.filter { $0.type == type }
        }
    ```
    
    이때 `filter`로 연산과정을 거쳐 `List`를 주게 된다. 
    
    또 각각의 `case`마다 `List`의 갯수를 알아야 해서 리스트의 갯수를 뽑아올 수 있도록 메서드를 만들었다.
    
    ```swift
    func todoCount(type: ProjectStatus) -> String {
            return projectList.filter { $0.type == type }.count.description }
    ```
    
    이럴 경우 한 `View`를 만드는데 `filter` 과정이 두번 진행된다. 
    현재 `case`가 3개니 총 `filter` 과정이 **6번** 진행된다. 연산과정이 불필요하게 많아진 느낌인데, 이를 더 줄일 수 있는 방법은 없을까하고 팀원들끼리 고민을 하였다.
    
    1. 각각의 `Case`마다 배열을 만들어 `List`마다 따로 관리한다.
        
        ```swift
        
        //각각 할일 리스트에 대한 배열을 생성함.
        var todoList = [Todo]()
        var doingList = [Todo]()
        var doneList = [Todo]()
        
        // CRUD를 진행할때마다 case를 비교를 해줘야함.
        // 효율적이라 생각하지 않음.
        private func createProject(_ project: Todo) {
            switch project.type {
             case .toDo:
               toDoList.append(project)
            case .doing:
               doingList.append(project)
            case .done:
                doneList.append(project)
          }
        }
        ```
        
        - 이럴경우 현재 리스트의 `CRUD`의 과정이 전부 `case`마다 비교를 해줘야 하기 때문에  `CRUD` 코드를 전부 분기처리해야 된다는 점에서 비효율적이라 판단하여 진행하지 않았다.
            
            
    2. `filteredList(type:)` 메서드를 사용할때 Count를 계산한다.
        
        ```swift
        // ViewModel
        final class ProjectListViewModel: ObservableObject{
            @Published private(set) var projectList: [Project] = []
        		private(set) var count: [ProjectStatus: Int] = [.todo: 0, .doing: 0, .done: 0]
            
        		...
        
            func filteredList(type: ProjectStatus) -> [Project] {
                let list = projectList.filter {
                    $0.type == type
                }
                **count[type] = list.count**
                return list
            }
        
            func todoCount(type: ProjectStatus) -> String {
                guard let count = count[type] else { return "0" }
                **return String(count)**
            }
        
        // View
        // 먼저 Count를 계산
        Text(String(todoListViewModel.todoCount(type)))
          List {
        	//현재 리스트의 Count를 계산하는 로직이 한템포 뒤에 있음.
          ForEach(todoListViewModel.fetchList(type: type)) { todo in
                  TodoRowView(todo: todo)
              }
        ```
        
        1. 해당 방법이 좋은 걸로 판단되었으나 뷰에서 해당 메서드를 사용하기 전에 `Count`를 계산해버리기 때문에, 갯수가 계속 한템포 느리게 반영됨.
            1. `@Published` 랩퍼를 이용하여 `View` 를  바로 그리게끔 하였으나, 트러블 슈팅중  **Published 프로퍼티가 동시에 변경되면서 뷰를 순환적으로 다시 그리는 이슈(CPU 오버헤딩) `해당문제가 생김.`**

---

## V. 관련학습 내용
<details>
<summary>1. Swift UI</summary>

[Lecture 1: Getting started with SwiftUI](https://www.youtube.com/watch?v=bqu6BquVi2M&list=PLpGHT1n4-mAsxuRxVPv7kj4-dQYoC3VVu&index=1)

[SwiftUI: ToolBar Item & Toolbar Group (2021, Xcode 12, SwiftUI) - iOS Development for Beginners](https://www.youtube.com/watch?v=6I3U5dY0zY4)
    
[[Mastering SwiftUI] Managing Selection](https://www.youtube.com/watch?v=F1mMdXe_jQs)
    
[SwiftUI : ForEach](https://seons-dev.tistory.com/33)
    
[Getting Started with Cloud Firestore and SwiftUI](https://www.raywenderlich.com/11609977-getting-started-with-cloud-firestore-and-swiftui)
</details>
        

<details>
<summary>2. Property Wrapper</summary>

[All SwiftUI property wrappers explained and compared](https://www.hackingwithswift.com/quick-start/swiftui/all-swiftui-property-wrappers-explained-and-compared)
    
[SwiftUI : @Environment 프로퍼티 래퍼](https://seons-dev.tistory.com/169)    
</details>
        
<details>
<summary>3. CoreData</summary>

[iOS) [번역] 코어데이터와 멀티스레딩](https://sihyungyou.github.io/iOS-coredata-multithreaded/)

[Apple Developer Documentation](https://developer.apple.com/documentation/coredata)

[SQL, NOSQL 개념 및 장단점](http://blog.knowgari.com/db%EC%B0%A8%EC%9D%B4/)

[Core Data Tutorial - Lesson 2: Set up Core Data in Your Xcode Project (New or Existing)](https://www.youtube.com/watch?v=1jv0zDUypcA&list=PLMRqhzcHGw1aDYKmCuqXQ_IqpWpJlpoJ3&index=2)
</details>

<details>
<summary>4. FireBase</summary>

[Apple 프로젝트에 Firebase 추가 | Firebase Documentation](https://firebase.google.com/docs/ios/setup?hl=ko)

[iOS ) 왕초보를 위한 Firebase사용법!/오류 해결](https://zeddios.tistory.com/47)

[https://github.com/firebase/firebase-ios-sdk.git](https://github.com/firebase/firebase-ios-sdk.git)
</details>

<details>
<summary>5. MVVM</summary>  

- 스위프트 UI를 사용하면 MVVM 디자인 패턴으로 앱을 제작하기 쉽다.
    
    ### Model
    
    - 모델은 UI에 들어갈 데이터들을 담고 있다.
    - 데이터를 구성하기 위해 필요한 `Logic`도 담고 있다.
    
    ### View
    
    - 단지 화면을 나타내는 `View`만 구성이 된다. `import SwiftUI or UIKit`  을 해서 쓰게된다.
    - 어떠한 경우에도 `Data`에 대한 로직이 존재하면 안된다.
    - `State`도 `View`에 상태변화에 따라 `View`를 다르게 그려줄 뿐이지 이게 `Data`를 건드는 행위가 아니다.
        - 예시로 다양한 `View`들의 **테마**가 있을때, `State`를 활용한다. 해당 `State`에 따라 `View`가 바뀌게 된다.
        - `View`가 어떻게 보여야 되는지는 해당`body var` 만 알고 있다. 그리고 그렇게 해야된다.
    - 모델에 변경사항이 있을때마다 해당 변경사항에 의존하는 모든 `View`에 `Body var`를 요청해야된다.
    매우 효율적인 시스템이 있어야한다.그렇지 않으면 UI전체를 지속적으로 그리게 된다.
    
    ### ViewModel
    
    - `View`를 `Model`에 바인딩(엮어서) 하여 `Model`의 변경 사항으로 인해 `View`가 반응하고 다시 그리도록 하는 것이다.
    - `View`와 `Model` 사이에 인터프리터? 역활을 할 수 도 있다.
    - `Model`에서 `RestFul` 을 요청하거나 데이터를 SQL 저장하거나 하는 로직은 `Model`이 복잡해지게 된다.
    따라서 `ViewModel`은 모든 작업을 수행하고 `View`에게 가공된 데이터를 준다.
    - `ViewModel`은 `Model`의 게이트키퍼 (문지기) 역활도 하며 특히 모델을 변경할 때 모델에 대한 엑세스가 제대로 작동하는지 확인한다.

- 기본적인 데이터 흐름은 다음과 같다.
    
    ![데이터흐름 이미지1](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/39b4620f-a495-4acb-99b9-60251b341979/Untitled.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211127%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211127T061303Z&X-Amz-Expires=86400&X-Amz-Signature=5e4fd936a0f9d2412797351f73351509601efef18e9797c52e18da0b387df23d&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Untitled.png%22&x-id=GetObject)
    
    - ViewModel은 Model의 변경사항을 지속적으로 알아 차린다. 
    변경 사항을 감지하면 즉시 **변경된 사항** 을 알리게 된다. (subscriber에게) 특정한 View를 알고 있는게 아니기 때문에 불특정 다수에게 알린다고 볼 수 있겠다.
        Model의 변경된 사항을 알고 싶은건 결국 `subscriber(View)` 가 해야 될 일이다.
    `ViewModel`이 `Model`의 변경사항을 `Publishes`(게시) 하는걸 구독하는 건 결국 `View`다. 
    이렇게 되면 `Model`에서 `View`로 가는 데이터의 흐름은 얼추 알게 된다.
    - 자 그러면 View에서 발생하는 유저의 이벤트에 대해 Model이 바뀌어야 된다면 어떻게 해야 될까?
        - 이벤트란 탭, 스와이프, UI탐색등등
        
        해당 이벤트로 모델이 변경 될 것이다. 이때 ViewModel에 사용자의 이벤트를 처리하는 또 다른 책임이 추가되어 이를 처리하도록 지시한다.
        
        ![데이터흐름 이미지2](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/01bf1042-608e-495c-aaf5-2c1a379e54a8/Untitled.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20211127%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20211127T061319Z&X-Amz-Expires=86400&X-Amz-Signature=eea094ea6beba2fe223c9738a074322c400be78e9e5cea1456c1474528a27dd5&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Untitled.png%22&x-id=GetObject)
        
        - 위의 그림과 같이 흐름의 화살표를 보면 좀 더 이해가 쉽다.
        
        [도대체 어떻게 하는 것이 MVVM 인것이냐? 오늘 결론 내립니다.](https://www.youtube.com/watch?v=M58LqynqQHc&t=1339s)

</details>

<details>
<summary>6. Repository Pattern</summary>
    
[[Design Pattern] Repository패턴이란](https://eunjin3786.tistory.com/198)
</details>
