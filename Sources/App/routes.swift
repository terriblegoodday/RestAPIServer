import Fluent
import Vapor

func routes(_ app: Application) throws {
    let passwordProtected = app.grouped(User.authenticator())

    app.get { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req -> String in
        #if DEBUG
            let env = "DEBUG"
        #else
            let env = "PRODUCTION"
        #endif
        return "Hello, world! Current environment: \(env)"
    }

    app.post("user") { req async throws -> User in
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        let user = try User(
            name: create.name,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        try await user.save(on: req.db)
        return user
    }

    passwordProtected.post("login") { req -> User in
        try req.auth.require(User.self)
    }

    passwordProtected.get("todo") { req -> [Todo] in
        let user = try req.auth.require(User.self)
        guard let id = user.id else {
            return []
        }
        return (try? await Todo.query(on: req.db).with(\.$user).filter(\.$user.$id == id).all()) ?? []
    }

    passwordProtected.post("todo") { req -> Todo in
        let user = try req.auth.require(User.self)
        try Todo.Create.validate(content: req)
        let create = try req.content.decode(Todo.Create.self)
        let todo = Todo(user: user,
                            title: create.title,
                            completed: create.completed ?? false)
        try await todo.save(on: req.db)
        return todo
    }

    passwordProtected.put("todo") { req -> Todo.UpdateResponse in
        let user = try req.auth.require(User.self)
        let update = try req.content.decode(Todo.Update.self)
        guard let id = update.id, let userId = user.id else {
            return Todo.UpdateResponse(success: false, todo: nil)
        }
        guard let todo = try await Todo.find(id, on: req.db),
              todo.$user.id == userId else {
            return Todo.UpdateResponse(success: false, todo: nil)
        }
        todo.title = update.title
        if let completed = update.completed {
            todo.completed = completed
        }
        try await todo.update(on: req.db)
        return Todo.UpdateResponse(success: true,
                                   todo: todo)
    }

    passwordProtected.delete("todo") { req -> Todo.RemoveResponse in
        let user = try req.auth.require(User.self)
        let remove = try req.content.decode(Todo.Remove.self)
        guard let id = remove.id, let userId = user.id else {
            return Todo.RemoveResponse(success: false)
        }
        guard let todo = try await Todo.find(id, on: req.db),
              todo.$user.id == userId else {
            return Todo.RemoveResponse(success: false)
        }
        try await todo.delete(on: req.db)
        return Todo.RemoveResponse(success: true)
    }

    try app.register(collection: TodoController())
    try app.register(collection: FilesController())
}
