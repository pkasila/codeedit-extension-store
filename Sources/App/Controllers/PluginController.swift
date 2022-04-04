//
//  PluginController.swift
//  
//
//  Created by Pavel Kasila on 1.04.22.
//

import Fluent
import Vapor

struct PluginController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let plugins = routes.grouped("plugins")

        let user = plugins.grouped(UserToken.authenticator(), UserToken.guardMiddleware())
        user.post(use: create)
        user.group(":pluginID") { plugin in
            user.get(use: get)
            user.delete(use: delete)
        }

        let maintainer = plugins.grouped(MaintainerToken.authenticator(), MaintainerToken.guardMiddleware())
        maintainer.post(":pluginID/ban", use: ban)
        maintainer.get("banned", use: indexBanned)

        plugins.get(use: index)
    }

    // MARK: - Anyone

    func index(req: Request) async throws -> Page<Plugin> {
        try await Plugin.query(on: req.db).paginate(for: req)
    }

    func get(req: Request) async throws -> Plugin {
        guard let plugin = try await Plugin.find(req.parameters.get("pluginID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return plugin
    }

    // MARK: - Authorized user

    func create(req: Request) async throws -> PluginAddResponse {
        let user = try req.auth.require(UserToken.self)
        let plugin = try req.content.decode(Plugin.Create.self).toPlugin(user: user.sub)
        try await plugin.save(on: req.db)

        switch plugin.management {
        case .githubReleases:
            let secret = try PluginHookInfo.generateSecret()
            let hookInfo = PluginHookInfo(secretData: secret.1, pluginID: try plugin.requireID())
            try await hookInfo.save(on: req.db)

            return .init(plugin: plugin, secret: secret.0)
        case .codeedit:
            return .init(plugin: plugin, secret: nil)
        }
    }

    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(UserToken.self)
        guard let plugin = try await Plugin.find(req.parameters.get("pluginID"), on: req.db) else {
            throw Abort(.notFound)
        }

        if user.sub != plugin.author {
            throw Abort(.forbidden)
        }

        try await plugin.delete(on: req.db)
        return .ok
    }

    // MARK: - Maintainer

    func indexBanned(req: Request) async throws -> Page<Plugin> {
        try await Plugin.query(on: req.db).filter(\.$ban != nil).paginate(for: req)
    }

    func ban(req: Request) async throws -> HTTPStatus {
        let maintainer = try req.auth.require(MaintainerToken.self)

        guard let banReason = req.body.string else {
            throw Abort(.badRequest)
        }

        guard let plugin = try await Plugin.find(req.parameters.get("pluginID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await plugin.delete(on: req.db)
        plugin.ban = .init(bannedBy: maintainer.sub, reason: banReason)
        try await plugin.save(on: req.db)

        return .ok
    }
}

struct PluginAddResponse: Content {
    var plugin: Plugin
    var secret: String?
}
