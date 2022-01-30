import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)


    app.migrations.add(CreateTodo(), User.Migration())
    try app.autoMigrate().wait()

    app.views.use(.leaf)

    app.routes.defaultMaxBodySize = "10mb"

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Int(ProcessInfo.processInfo.environment["PORT"]!)!

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
