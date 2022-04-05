//
//  File.swift
//  
//
//  Created by Pavel Kasila on 5.04.22.
//

import Fluent
import Vapor

struct PluginReleaseController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let plugins = routes.grouped("plugins")

        // anyone
        plugins.get(":pluginID/releases", use: index)
        routes.get("releases/:releaseID", use: get)
    }

    func index(req: Request) async throws -> Page<PluginRelease> {
        try await PluginRelease.query(on: req.db)
            .filter("plugin_id", .equal, req.parameters.get("releaseID")).paginate(for: req)
    }

    func get(req: Request) async throws -> PluginRelease {
        guard let plugin = try await PluginRelease.find(req.parameters.get("releaseID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return plugin
    }
}
