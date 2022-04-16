import Fluent
import FluentPostgresDriver
import JWT
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)

    app.migrations.add(CreatePlugin())
    app.migrations.add(CreatePluginRelease())
    app.migrations.add(CreatePluginHookInfo())
    app.migrations.add(AddLanguageServerToSDKType())

    try app.client.get(URI(string: Environment.get("KEYCLOAK_JWKS_URL") ?? "https://keycloak.pkasila.net/auth/realms/CodeEdit/protocol/openid-connect/certs"))
        .flatMapThrowing { (response: ClientResponse) in
            let jwks = try JSONDecoder().decode(JWKS.self, from: response.body!)
            try app.jwt.signers.use(jwks: jwks)
        }
        .wait()

    // register routes
    try routes(app)
}
