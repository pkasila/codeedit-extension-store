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
        routes.get("releases/:releaseID", use: get)
    }

    func get(req: Request) async throws -> PluginRelease {
        guard let plugin = try await PluginRelease.find(req.parameters.get("releaseID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return plugin
    }
}
