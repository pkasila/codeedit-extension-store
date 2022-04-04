import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: PluginController())
    try app.register(collection: WebhooksController())
}
