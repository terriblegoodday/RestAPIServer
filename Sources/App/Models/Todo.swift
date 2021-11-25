import Fluent
import Vapor

final class Todo: Model, Content {
    static let schema = "todos"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "title")
    var title: String

    @Field(key: "completed")
    var completed: Bool?

    init() { }

    init(id: UUID? = nil, user: User, title: String, completed: Bool? = false) {
        self.$user.id = user.id!
        self.id = id
        self.title = title
        self.completed = completed
    }
}

extension Todo {
    struct Create: Content {
        var title: String
        var completed: Bool? = false
    }

    struct Remove: Content {
        var id: UUID?
    }

    struct Update: Content {
        var id: UUID?
        var title: String
        var completed: Bool?
    }

    struct RemoveResponse: Content {
        var success: Bool
    }

    struct UpdateResponse: Content {
        var success: Bool
        var todo: Todo?
    }
}

extension Todo.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty)
    }
}
